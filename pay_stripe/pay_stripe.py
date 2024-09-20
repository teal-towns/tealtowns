import re
import stripe

from common import mongo_db_crud as _mongo_db_crud
import mongo_db
from user_payment import user_payment as _user_payment

import ml_config
_config = ml_config.get_config()

def StripePaymentLink(amountUSD: float, userId: str, title: str, forId: str, forType: str,
    recurringInterval: str = '', recurringIntervalCount: int = 1, quantity: int = 1):
    ret = { 'valid': 1, 'message': '', 'url': '', 'priceId': '',
        'userId': userId, 'forId': forId, 'forType': forType, }
    # title = GetPaymentName(title, '')
    stripe.api_key = _config['stripe']['secret']
    res = None
    recurring = False
    if recurringInterval in ['day', 'week', 'month', 'year']:
        recurring = True
        res = stripe.Price.create(
            unit_amount=int(amountUSD * 100),
            currency="usd",
            product_data={
                "name": title,
            },
            recurring={"interval": recurringInterval, "interval_count": recurringIntervalCount},
        )
    else:
        res = stripe.Price.create(
            unit_amount=int(amountUSD * 100),
            currency="usd",
            product_data={
                "name": title,
            },
        )

    priceId = res['id']
    ret['priceId'] = priceId

    metadata = {
        'forId': forId,
        'forType': forType,
        'quantity': quantity,
        'userId': userId,
        'stripePriceId': priceId,
    }
    if recurring:
        metadata['recurringInterval'] = recurringInterval
        metadata['recurringIntervalCount'] = recurringIntervalCount
        res = stripe.PaymentLink.create(
            line_items=[
                {"price": priceId, "quantity": 1}
            ],
            metadata = metadata,
            subscription_data={"metadata": metadata},
        )
    else:
        res = stripe.PaymentLink.create(
            line_items=[
                {"price": priceId, "quantity": 1}
            ],
            metadata = metadata,
        )

    ret['url'] = res['url']

    return ret

# def GetPaymentName(title: str, suffix: str = '', maxLen: int = 25):
#     title = title.lower()
#     regex = re.compile('[^a-zA-Z0-9 ]')
#     title = regex.sub('', title)
#     if len(title) > maxLen:
#         title = title[slice(0, maxLen)]
#     return title + suffix

# https://docs.stripe.com/connect/add-and-pay-out-guide?dashboard-or-api=api
def StripeAccountLink(userId: str):
    ret = { 'valid': 1, 'message': '', 'url': '', 'userStripeAccount': {}, 'userId': userId, }
    stripe.api_key = _config['stripe']['secret']
    # First see if user already has one.
    userStripeAccount = mongo_db.find_one('userStripeAccount', { 'userId': userId })['item']
    createNew = 1
    if userStripeAccount is not None:
        ret['userStripeAccount'] = userStripeAccount
        accountId = userStripeAccount['stripeConnectedAccountId']
        createNew = 0
        # Check if complete.
        if userStripeAccount['status'] != 'complete':
            try:
                res = stripe.Account.retrieve(userStripeAccount['stripeConnectedAccountId'])
                if res['charges_enabled']:
                    userStripeAccount['status'] = 'complete'
                    _mongo_db_crud.Save('userStripeAccount', userStripeAccount)
                    ret['userStripeAccount'] = userStripeAccount
                    return ret
            except Exception as e:
                print ('error', e)
                pass

    if createNew:
        res = stripe.Account.create(type="express")
        accountId = res['id']
    refreshUrl = _config['web_server']['urls']['base'] + '/user-money'
    returnUrl = _config['web_server']['urls']['base'] + '/user-money'
    # No metadata field.. Need to use returnUrl and set this on frontend..
    # metadata = {
    #     'userId': userId,
    # }
    # Always need to re-get url as they expire within minutes.
    res = stripe.AccountLink.create(account = accountId, refresh_url = refreshUrl,
        return_url = returnUrl, type="account_onboarding")

    if createNew:
        # Save in database as pending.
        userStripeAccount = {
            'userId': userId,
            'stripeConnectedAccountId': accountId,
            'status': 'pending',
        }
        _mongo_db_crud.Save('userStripeAccount', userStripeAccount)

    ret['url'] = res['url']
    return ret

def StripeCancelSubscription(subscriptionId: str):
    ret = { 'valid': 1, 'message': '', }
    stripe.api_key = _config['stripe']['secret']
    res = stripe.Subscription.cancel(subscriptionId)
    if res['status'] != 'canceled':
        ret['valid'] = 0
        ret['message'] = 'Failed to cancel subscription.'
    return ret

def StripePayUser(userId: str, amountUSD: float):
    ret = { 'valid': 1, 'message': '', 'userMoney': {}, 'availableUSD': 0, }
    userStripeAccount = mongo_db.find_one('userStripeAccount', { 'userId': userId })['item']
    if userStripeAccount is None:
        ret['valid'] = 0
        ret['message'] = 'No user stripe account.'
        return ret
    # Check money balance.
    retMoney = _user_payment.GetUserMoneyAndPending(userId)
    if retMoney['availableUSD'] < amountUSD:
        ret['valid'] = 0
        ret['message'] = 'The  max you can withdraw is $' + str(retMoney['availableUSD']) + '.'
        return ret
    accountId = userStripeAccount['stripeConnectedAccountId']
    stripe.api_key = _config['stripe']['secret']
    try:
        transfer = stripe.Transfer.create(amount = int(amountUSD * 100), currency = 'usd', destination = accountId)
        if transfer is None or 'id' not in transfer:
            ret['valid'] = 0
            ret['message'] = 'Could not transfer.'
    except Exception as e:
        print ('error', e)
        ret['valid'] = 0
        ret['message'] = 'Could not transfer.'
        return ret
    # Add payment.
    retPay = _user_payment.AddPayment(userId, -1 * amountUSD, 'withdrawToBank', transfer['id'])
    if not retPay['valid']:
        return retPay
    retMoney = _user_payment.GetUserMoneyAndPending(userId)
    ret['userMoney'] = retMoney['userMoney']
    ret['availableUSD'] = retMoney['availableUSD']
    return ret
