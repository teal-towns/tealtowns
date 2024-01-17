import datetime
import math
import re
import stripe

import ml_config
_config = ml_config.get_config()

import date_time
import mongo_db
from shared_item import shared_item_owner as _shared_item_owner
from shared_item import shared_item_payment_math as _shared_item_payment_math
from user_payment import user_payment as _user_payment

def CanStartPurchase(sharedItem: dict):
    ret = { 'valid': 1, 'message': '', 'canStartPurchase': 0 }
    # Is fully funded?
    if not sharedItem['bought'] and sharedItem['fundingRequired'] > 0:
        return ret
    # Enough owners?
    if sharedItem['pledgedOwners'] < sharedItem['minOwners']:
        return ret
    # Need enough payments.
    # if sharedItem['pledgedOwners'] >= sharedItem['maxOwners']:
    #     ret['canStartPurchase'] = 1
    #     return ret
    # Enough pledged payments from owners?
    purchaseOwners = GetPurchaseOwners(sharedItem)
    if len(purchaseOwners) > 0:
        ret['canStartPurchase'] = 1

    return ret

# We want to take the most owners we can who all have pledged at or above the monthly price for this number of owners.
def GetPurchaseOwners(sharedItem: dict):
    retOwners = _shared_item_owner.GetNextGenerationOwners(sharedItem)
    sharedItemOwners = retOwners['sharedItemOwners']
    numOwners = sharedItem['pledgedOwners']
    while numOwners >= sharedItem['minOwners']:
        retPayments = _shared_item_payment_math.GetPayments(sharedItem['currentPrice'], sharedItem['monthsToPayBack'],
            numOwners, sharedItem['maintenancePerYear'])
        ownersAbovePrice = []
        for owner in sharedItemOwners:
            if not int(owner['investorOnly']):
                if owner['totalPaid'] >= retPayments['totalPerPerson'] or \
                    (owner['monthlyPayment'] >= retPayments['monthlyPayment'] and \
                    owner['totalPaid'] >= retPayments['downPerPerson']):
                    ownersAbovePrice.append(owner)
        if len(ownersAbovePrice) >= numOwners:
            return ownersAbovePrice
        numOwners -= 1
    return []

def StartPurchase(sharedItem: dict, now = None):
    now = date_time.now() if now is None else now
    ret = { 'valid': 1, 'message': '', }

    # Must get BEFORE update generation.
    retOwners = _shared_item_owner.GetNextGenerationOwners(sharedItem)
    owners = []
    investors = []
    sharedItemOwnerIds = []
    # To link payments, map user id to owner.
    userIdOwnersMap = {}
    maxPaid = 0
    purchaser = {}
    # Separate owners and investors. Find purchaser (person who paid the most).
    for owner in retOwners['sharedItemOwners']:
        if not int(owner['investorOnly']):
            owners.append(owner)
            sharedItemOwnerIds.append(owner['_id'])
            userIdOwnersMap[owner['userId']] = owner
        else:
            investors.append(owner)
        if (not sharedItem['bought'] and owner['totalPaid'] > maxPaid) or \
            (sharedItem['bought'] and owner['userId'] == sharedItem['currentOwnerUserId']):
            maxPaid = owner['totalPaid']
            purchaser = owner
    # Set purchaser
    query = {
        '_id': mongo_db.to_object_id(sharedItem['_id']),
    }
    sharedItemMutation = {
        '$set': {
            'generation': sharedItem['generation'] + 1,
            'currentGenerationStart': date_time.string(now),
            'currentPurchaserUserId': purchaser['userId'],
        }
    }
    if sharedItem['bought']:
        sharedItemMutation['$set']['status'] = 'owned'
    else:
        sharedItemMutation['$set']['status'] = 'purchasing'
    retUpdate = mongo_db.update_one('sharedItem', query, sharedItemMutation)

    # Get down payments.
    query = {
        'forType': 'sharedItemOwner',
        'forId': { '$in': sharedItemOwnerIds },
        'status': 'pending',
    }
    userPayments = mongo_db.find('userPayment', query)['items']

    # Get total owed.
    totalDown = 0
    paymentInfo = _shared_item_payment_math.GetPayments(sharedItem['currentPrice'], sharedItem['monthsToPayBack'],
        len(owners), sharedItem['maintenancePerYear'])
    owedPerPerson = paymentInfo['totalPerPerson']

    # Pay down payments.
    for userPayment in userPayments:
        amountTemp = abs(userPayment['amountUSD'])
        totalDown += amountTemp
        # Set payment as complete
        retPay = _user_payment.UpdatePayment(userPayment['_id'], 'complete', removeCutFromBalance = 1)
        # Add payment to purchaser
        ownerTemp = userIdOwnersMap[userPayment['userId']]
        retPay = _user_payment.AddPayment(purchaser['userId'], abs(userPayment['amountUSD']), 'sharedItemOwner',
            ownerTemp['_id'], status = 'complete')
        # Update owed
        query = {
            '_id': mongo_db.to_object_id(ownerTemp['_id']),
        }
        # Check if all paid with down payment, otherwise will start monthly payments.
        status = 'pendingMonthlyPayment'
        if amountTemp >= owedPerPerson:
            status = 'paid'
        mutation = {
            '$set': {
                'totalOwed': owedPerPerson,
                'status': status,
            }
        }
        retUpdate = mongo_db.update_one('sharedItemOwner', query, mutation)

    # Update purchaser
    query = {
        '_id': mongo_db.to_object_id(purchaser['_id']),
    }
    mutation = {
        '$set': {
            'totalOwed': -1 * paymentInfo['totalToPayBack'],
            'status': 'paid',
        },
        '$inc': {
            'totalPaidBack': totalDown,
        },
    }
    retUpdate = mongo_db.update_one('sharedItemOwner', query, mutation)

    return ret

def MakeOwnerPayment(sharedItemOwnerId: str, amountUSD: float):
    ret = { 'valid': 1, 'message': '', }

    amountUSD = abs(amountUSD)
    retOwner = _shared_item_owner.Get(sharedItemOwnerId, withSharedItem = 1)
    sharedItemOwner = retOwner['sharedItemOwner']
    sharedItem = retOwner['sharedItem']

    # Charge owner
    _user_payment.AddPayment(sharedItemOwner['userId'], -1 * amountUSD, 'sharedItemOwner',
        sharedItemOwner['_id'], removeCutFromBalance = 1)
    query = {
        '_id': mongo_db.to_object_id(sharedItemOwner['_id']),
    }
    newTotalPaid = sharedItemOwner['totalPaid'] + amountUSD
    mutation = {
        '$set': {
            'totalPaid': newTotalPaid,
        }
    }
    if newTotalPaid >= sharedItemOwner['totalOwed']:
        mutation['$set']['status'] = 'paid'
        StopStripePayment(sharedItemOwner['stripePriceId'])
    retUpdate = mongo_db.update_one('sharedItemOwner', query, mutation)

    # Pay investor
    query = {
        'userId': sharedItem['currentPurchaserUserId'],
        'sharedItemId': sharedItem['_id'],
        'generation': sharedItem['generation'],
    }
    purchaser = mongo_db.find_one('sharedItemOwner', query)['item']
    _user_payment.AddPayment(purchaser['userId'], amountUSD, 'sharedItemOwner', sharedItemOwner['_id'])
    query = {
        '_id': mongo_db.to_object_id(purchaser['_id']),
    }
    newTotalPaidBack = purchaser['totalPaidBack'] + amountUSD
    mutation = {
        '$set': {
            'totalPaidBack': newTotalPaidBack,
        },
    }
    if newTotalPaidBack >= -1 * purchaser['totalOwed']:
        mutation['$set']['status'] = 'paid'
    retUpdate = mongo_db.update_one('sharedItemOwner', query, mutation)

    return ret

def ComputeMonthlyPaymentAmount(sharedItemOwnerId: str, now = None):
    now = date_time.now() if now is None else now
    ret = { 'valid': 1, 'message': '', 'monthlyPayment': 0, 'amountUSD': 0, 'sharedItemTitle': '',
        'monthsRemaining': 0, }
    retOwner = _shared_item_owner.Get(sharedItemOwnerId, withSharedItem = 1)
    sharedItemOwner = retOwner['sharedItemOwner']
    sharedItem = retOwner['sharedItem']
    amountRemaining = sharedItemOwner['totalOwed'] - sharedItemOwner['totalPaid']
    if amountRemaining <= 0:
        ret['valid'] = 0
        ret['message'] = 'No more money owed.'
        return ret

    endDate = date_time.nextMonth(date_time.from_string(sharedItem['currentGenerationStart']),
        months = sharedItem['monthsToPayBack'])
    monthsRemaining = date_time.diff(now, endDate, unit = 'days') / 30
    if monthsRemaining <= 0:
        monthsRemaining = 1
    ret['monthsRemaining'] = math.floor(monthsRemaining)
    ret['monthlyPayment'] = math.ceil(amountRemaining / monthsRemaining)
    monthlyPaymentWithFee = _shared_item_payment_math.AddFee(ret['monthlyPayment'])
    ret['amountUSD'] = monthlyPaymentWithFee
    ret['sharedItemTitle'] = sharedItem['title']

    return ret

def StopStripePayment(stripePriceId: str):
    ret = { 'valid': 1, 'message': '', }
    stripe.api_key = _config['stripe']['secret']
    res = stripe.Price.modify(
        stripePriceId,
        active = False,
    )
    return ret

def StripePaymentLinkDown(amountUSD: float, sharedItemTitle: str, sharedItemId: str, userId: str):
    ret = { 'valid': 1, 'message': '', 'url': '', 'priceId': '', }
    stripe.api_key = _config['stripe']['secret']
    res = stripe.Price.create(
        unit_amount=int(amountUSD * 100),
        currency="usd",
        product_data={
            "name": GetPaymentName(sharedItemTitle, ' (Down Payment)'),
        }
    )
    priceId = res['id']
    ret['priceId'] = priceId

    res = stripe.PaymentLink.create(
        line_items=[
            {"price": priceId, "quantity": 1}
        ],
        metadata = {
            'sharedItemId': sharedItemId,
            'userId': userId,
            'type': 'sharedItemDownPayment',
            'stripePriceId': priceId,
        },
    )
    ret['url'] = res['url']

    return ret

def StripePaymentLinkMonthly(sharedItemOwnerId: str):
    ret = { 'valid': 1, 'message': '', 'url': '', 'priceId': '', }

    retDetails = ComputeMonthlyPaymentAmount(sharedItemOwnerId)
    if not retDetails['valid']:
        return retDetails
    amountUSD = retDetails['amountUSD']
    sharedItemTitle = retDetails['sharedItemTitle']
    monthsRemaining = retDetails['monthsRemaining']
    monthlyPayment = retDetails['monthlyPayment']
    
    stripe.api_key = _config['stripe']['secret']
    res = stripe.Price.create(
        unit_amount=int(amountUSD * 100),
        currency="usd",
        recurring={"interval": "month"},
        product_data={
            "name": GetPaymentName(sharedItemTitle, ' (for ' + str(monthsRemaining) + ' months)'),
        }
    )
    priceId = res['id']
    ret['priceId'] = priceId

    metadata = {
        'sharedItemOwnerId': sharedItemOwnerId,
        'sharedItemId': sharedItemOwner['sharedItemId'],
        'userId': sharedItemOwner['userId'],
        'type': 'sharedItemMonthlyPayment',
        'stripeMonthlyPriceId': priceId,
        'monthlyPayment': monthlyPayment,
    }
    res = stripe.PaymentLink.create(
        line_items=[
            {"price": priceId, "quantity": 1}
        ],
        metadata = metadata,
        payment_intent_data = {
            metadata: metadata
        }
    )
    ret['url'] = res['url']

    return ret

def GetPaymentName(sharedItemTitle: str, suffix: str = '', maxLen: int = 25):
    title = sharedItemTitle.lower()
    regex = re.compile('[^a-zA-Z0-9 ]')
    title = regex.sub('', title)
    if len(title) > maxLen:
        title = title[slice(0, maxLen)]
    return title + suffix
