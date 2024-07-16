import math

from common import mongo_db_crud as _mongo_db_crud
import date_time
import mongo_db
from shared_item import shared_item_payment_math as _shared_item_payment_math
from event import event_payment as _event_payment
from event import user_event as _user_event
from event import weekly_event as _weekly_event
from pay_mercury import pay_mercury as _pay_mercury
from pay_stripe import pay_stripe as _pay_stripe
from shared_item import shared_item as _shared_item
from user_auth import user as _user

def AddPayment(userId: str, amountUSD: float, forType: str, forId: str, status: str = 'complete', notes: str = '',
    removeCutFromBalance: int = 0, amountUSDPreFee: float = 0, quantity: int = 1):
    amountUSDPreFee = amountUSDPreFee if amountUSDPreFee != 0 else amountUSD
    ret = _mongo_db_crud.Save('userPayment', {
        'userId': userId,
        'amountUSD': amountUSD,
        'amountUSDPreFee': amountUSDPreFee,
        'forType': forType,
        'forId': forId,
        'quantity': quantity,
        'status': status,
        'notes': notes,
    })
    if status == 'complete':
        UpdateBalance(userId, amountUSD, removeCutFromBalance = removeCutFromBalance)
        CheckMoveRevenueToBank(amountUSDPreFee, forType, forId, quantity = quantity)
    return ret

def UpdatePayment(userPaymentId: str, status: str, removeCutFromBalance: int = 0):
    query = {
        '_id': mongo_db.to_object_id(userPaymentId),
    }
    mutation = {
        '$set': {
            'status': status,
        }
    }
    ret = mongo_db.update_one('userPayment', query, mutation)
    if status == 'complete':
        item = mongo_db.find_one('userPayment', query)["item"]
        UpdateBalance(item['userId'], item['amountUSD'], removeCutFromBalance = removeCutFromBalance)
        CheckMoveRevenueToBank(item['amountUSDPreFee'], item['forType'], item['forId'], quantity = item['quantity'])
    return ret

def AddPaymentSubscription(userPaymentSubscription: dict):
    ret = _mongo_db_crud.Save('userPaymentSubscription', userPaymentSubscription)
    # Actual money will come directly from recurring paid invoices; this just records that a subscription was completed.
    return ret

def CancelSubscription(userPaymentSubscriptionId: str):
    ret = { 'valid': 1, 'message': '', 'credits': 0 }
    query = { '_id': mongo_db.to_object_id(userPaymentSubscriptionId) }
    userPaymentSubscription = mongo_db.find_one('userPaymentSubscription', query)['item']
    if userPaymentSubscription is not None and userPaymentSubscription['status'] == 'complete':
        if 'subscription' in userPaymentSubscription['stripeIds']:
            retCancel = _pay_stripe.StripeCancelSubscription(userPaymentSubscription['stripeIds']['subscription'])
            if not retCancel['valid']:
                ret['valid'] = 0
                ret['message'] = retCancel['message']
                return ret

        mutation = { '$set': { 'status': 'canceled' } }

        # Cancel / update any related data too.
        if userPaymentSubscription['forType'] == 'weeklyEvent':
            retCredits = _user_event.GiveEndSubscriptionCredits(userPaymentSubscription['forId'],
                userPaymentSubscription['userId'])
            ret['credits'] = retCredits['credits']
            if retCredits['credits'] > 0:
                mutation['$set']['credits'] = retCredits['credits']
            mongo_db.delete_one('userWeeklyEvent', { 'weeklyEventId': userPaymentSubscription['forId'],
                'userId': userPaymentSubscription['userId'] })

        mongo_db.update_one('userPaymentSubscription', query, mutation)
    return ret

def GetSubscriptionPaymentsRemaining(userPaymentSubscription: dict, mostRecentPaidDate: str, now = None,
    payPeriodDays: int = 7):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 1, 'message': '', 'subscriptionPaymentsRemaining': 0, }
    daysRemaining = 0
    paymentDate = date_time.from_string(userPaymentSubscription['createdAt'])
    if userPaymentSubscription['recurringInterval'] == 'month':
        nextPaymentDay = paymentDate.day
        if nextPaymentDay > now.day:
            daysRemaining = nextPaymentDay - now.day
        else:
            daysRemaining = nextPaymentDay - now.day + 30
    elif userPaymentSubscription['recurringInterval'] == 'year':
        nextPaymentDate = date_time.create(now.year, paymentDate.month, paymentDate.day)
        if nextPaymentDate < now:
            nextPaymentDate = date_time.create(now.year + 1, paymentDate.month, paymentDate.day)
        daysRemaining = date_time.diff(now, nextPaymentDate, unit = 'days')
    ret['subscriptionPaymentsRemaining'] = round(daysRemaining / payPeriodDays)
    return ret


def CheckMoveRevenueToBank(amountUSDPreFee: float, forType: str, forId: str, recurringInterval: str = '',
    recurringIntervalCount: int = 0, quantity: int = 1):
    ret = { 'valid': 1, 'message': '', 'revenueUSD': 0, }
    # Only move revenue if a payment FROM the user.
    if amountUSDPreFee < 0:
        amount = abs(amountUSDPreFee)
        if forType == 'weeklyEvent' or forType == 'event':
            weeklyEvent = None
            if forType == 'event':
                event = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(forId)})['item']
                weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(event['weeklyEventId'])})['item']
            else:
                weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(forId)})['item']
            if weeklyEvent is not None:
                ret['revenueUSD'] = _event_payment.GetRevenue(amount, weeklyEvent['hostMoneyPerPersonUSD'],
                    recurringInterval, recurringIntervalCount, quantity)
        elif forType == 'sharedItem' or forType == 'sharedItemOwner':
            ret['revenueUSD'] = _shared_item_payment_math.GetRevenue(amount)

        if ret['revenueUSD'] > 0:
            revenue = ret['revenueUSD']
            retOne = _pay_mercury.QueueTransaction('MercuryEndUserFunds', 'MercuryUserRevenue', revenue, forId, forType)

    return ret

def UpdateBalance(userId: str, amountUSD: float, removeCutFromBalance: int = 0):
    amountFinal = amountUSD
    if removeCutFromBalance:
        amountFinal = amountUSD + _shared_item_payment_math.GetCut(amountUSD)

    query = {
        'userId': userId,
    }
    item = mongo_db.find_one('userMoney', query)["item"]
    if item is None:
        ret = _mongo_db_crud.Save('userMoney', {
            'userId': userId,
            'balanceUSD': amountFinal,
        })
    else:
        query = {
            'userId': userId,
        }
        mutation = {
            '$inc': {
                'balanceUSD': amountFinal,
            }
        }
        ret = mongo_db.update_one('userMoney', query, mutation)
    return ret

# def GetUserMoney(userId: str):
#     ret = { 'valid': 1, 'message': '', 'userMoney': {}, 'availableUSD': 0 }
#     query = {
#         'userId': userId,
#     }
#     item = mongo_db.find_one('userMoney', query)['item']
#     if item is not None:
#         ret['userMoney'] = item
#         ret['availableUSD'] = ret['userMoney']['balanceUSD']
#     return ret

def GetUserMoneyAndPending(userId: str):
    ret = { 'valid': 1, 'message': '', 'userMoney': {}, 'userPayments': [], 'availableUSD': 0 }
    query = {
        'userId': userId,
    }
    item = mongo_db.find_one('userMoney', query)['item']
    if item is not None:
        ret['userMoney'] = item

        query = {
            'userId': userId,
            'status': 'pending',
        }
        retPayments = _mongo_db_crud.Search('userPayment', query = query)
        ret['userPayments'] = retPayments['userPayments']
        ret['availableUSD'] = ret['userMoney']['balanceUSD']
        for payment in ret['userPayments']:
            ret['availableUSD'] += payment['amountUSD']

    return ret

def GetForLink(forType: str, forId: str):
    ret = { 'valid': 1, 'message': '', 'forLink': '' }
    if forType == 'weeklyEvent':
        item = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(forId)})['item']
        if item is not None:
            ret['forLink'] = _weekly_event.GetUrl(item)
    elif forType == 'event':
        item = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(forId)})['item']
        if item is not None:
            weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(item['weeklyEventId'])})['item']
            if weeklyEvent is not None:
                ret['forLink'] = _weekly_event.GetUrl(weeklyEvent)
    elif forType == 'sharedItemOwner':
        item1 = mongo_db.find_one('sharedItemOwner', {'_id': mongo_db.to_object_id(forId)})['item']
        if item1 is not None:
            item = mongo_db.find_one('sharedItem', {'_id': mongo_db.to_object_id(item1['sharedItemId'])})['item']
            if item is not None:
                ret['forLink'] = _shared_item.GetUrl(item, sharedItemOwnerId = forId)
    elif forType == 'sharedItem':
        item = mongo_db.find_one('sharedItem', {'_id': mongo_db.to_object_id(forId)})['item']
        if item is not None:
            ret['forLink'] = _shared_item.GetUrl(item)
    elif forType == 'user':
        item = mongo_db.find_one('user', {'_id': mongo_db.to_object_id(forId)})['item']
        if item is not None:
            ret['forLink'] = _user.GetUrl(item)
    return ret

def AddForLinks(payments: list):
    for payment in payments:
        payment['forLink'] = GetForLink(payment['forType'], payment['forId'])['forLink']
    return payments
