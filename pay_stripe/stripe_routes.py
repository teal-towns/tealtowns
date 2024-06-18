from aiohttp import web
import json
import stripe

import ml_config
_config = ml_config.get_config()

import lodash
from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import websocket_clients as _websocket_clients
from pay_stripe import pay_stripe as _pay_stripe
from shared_item import shared_item_payment as _shared_item_payment
from shared_item import shared_item_payment_math as _shared_item_payment_math
from user_payment import user_payment as _user_payment

def Routes(app, cors):
    resource = cors.add(app.router.add_resource('/web/stripe-webhooks'))
    cors.add(resource.add_route('POST', StripeWebhook))

# Stripe events on creating payment link with recurring (subscription):
# invoice: .created, .updated, .finalized, .paid .payment_suceeded, customer.subscription: .created, .updated, checkout.session.completed + more..
# Stripe events on recurring subscription payment:
# invoice: .created, .updated, .finalized, .paid .payment_suceeded, customer.subscription: .updated
# Stripe events for single payment:
# payment_intent: .created, .succeeded, charge: .succeeded, checkout.session.completed

# https://stripe.com/docs/testing
# https://stripe.com/docs/webhooks
# https://stripe.com/docs/api/checkout/sessions/object
# https://stripe.com/docs/payments/checkout/fulfill-orders
# https://stripe.com/docs/webhooks#register-webhook
async def StripeWebhook(request):
    stripe.api_key = _config['stripe']['secret']
    data = await request.json()
    # payload = await request.text()
    try:
        # event = stripe.Event.construct_from(json.loads(payload), stripe.api_key)
        event = stripe.Event.construct_from(data, stripe.api_key)
    except ValueError as e:
    # Invalid payload
        return web.Response(status=400)

    if event.type in ['checkout.session.completed', 'checkout.session.async_payment_succeeded']:
        data = event.data.object
        if data['status'] == 'complete' or data['status'] == 'open':
            if 'userId' in data['metadata']:
                # Need to extract from stripe object json format..
                data1 = {}
                for key in data['metadata']:
                    data1[key] = data['metadata'][key]
                    if key in ['quantity', 'recurringIntervalCount']:
                        data1[key] = int(data1[key])

                amount = data['amount_total'] / 100
                if 'forId' in data1 and 'forType' in data1:
                    if 'recurringInterval' in data1:
                        userPaymentSubscription = {
                            'userId': data1['userId'],
                            'amountUSD': amount,
                            'recurringInterval': data1['recurringInterval'],
                            'recurringIntervalCount': int(data1['recurringIntervalCount']),
                            'forType': data1['forType'],
                            'forId': data1['forId'],
                            'quantity': data1['quantity'],
                            'status': 'complete',
                            'stripeIds': {
                                'checkoutSession': data['id'],
                                'subscription': data['subscription'],
                            },
                            'credits': 0,
                        }
                        _user_payment.AddPaymentSubscription(userPaymentSubscription)
                    else:
                        _user_payment.AddPayment(data1['userId'], amount, data1['forType'],
                            data1['forId'], 'complete', quantity = data1['quantity'])
                else:
                    withoutPayFee = _shared_item_payment_math.RemoveFee(amount, withCut = False)
                    withoutFees = _shared_item_payment_math.RemoveFee(amount)
                    _user_payment.AddPayment(data['metadata']['userId'], withoutPayFee, 'sharedItem',
                        data['metadata']['sharedItemId'], 'complete', notes = 'Stripe down payment',
                        amountUSDPreFee = amount)
                    data1['totalPaid'] = withoutFees

                jsonData = {
                    'route': 'StripePaymentComplete',
                    'data': data1,
                }
                await _websocket_clients.SendToUsersJson(jsonData, [data['metadata']['userId']])
    elif event.type == 'checkout.session.async_payment_failed':
        data = event.data.object
        print ('checkout.session.async_payment_failed', data)
        # TODO

    elif event.type == 'invoice.paid':
        data = event.data.object
        if data['status'] == 'paid':
            if 'subscription_details' in data and 'metadata' in data['subscription_details'] and \
                'userId' in data['subscription_details']['metadata']:
                # Need to extract from stripe object json format..
                metadata = {}
                for key in data['subscription_details']['metadata']:
                    metadata[key] = data['subscription_details']['metadata'][key]
                    if key in ['quantity', 'recurringIntervalCount']:
                        metadata[key] = int(metadata[key])
                # Make negative to pass in as we only take revenue on payments from a user, which are negative amounts,
                # but subscriptions are always stored as positive.
                amountUSDPreFee = -1 * data['amount_paid'] / 100
                _user_payment.CheckMoveRevenueToBank(amountUSDPreFee, metadata['forType'], metadata['forId'],
                    metadata['recurringInterval'], metadata['recurringIntervalCount'], metadata['quantity'])

    # https://stripe.com/docs/api/payment_intents/object
    elif event.type == 'payment_intent.succeeded':
        data = event.data.object
        if data['status'] in ['succeeded', 'processing']:
            if 'userId' in data['metadata']:
                amount = data['amount'] / 100
                withoutPayFee = _shared_item_payment_math.RemoveFee(amount, withCut = False)
                withoutFees = _shared_item_payment_math.RemoveFee(amount)
                _user_payment.AddPayment(data['metadata']['userId'], withoutPayFee, 'sharedItemOwner',
                    data['metadata']['sharedItemOwnerId'], 'complete', notes = 'Stripe monthly payment',
                    amountUSDPreFee = amount)
                _shared_item_payment.MakeOwnerPayment(data['metadata']['sharedItemOwnerId'], withoutFees)

    elif event.type == 'payment_intent.payment_failed':
        # TODO
        pass

    # metadata is not allowed so have to manually get the account to check instead.
    # elif event.type == 'account.updated':
    #     data = event.data.object
    #     if 'id' in data:
    #         # Need to extract from stripe object json format..
    #         metadata = {}
    #         for key in data['metadata']:
    #             metadata[key] = data['metadata'][key]
    #         if 'userId' in metadata:
    #             retUserStripeAccount = _mongo_db_crud.Save('userStripeAccount', {
    #                 'userId': metadata['userId'],
    #                 'stripeAccountId': data['id'],
    #             })
    #             jsonData = {
    #                 'route': 'StripeAccountUpdated',
    #                 'data': {
    #                     'userId': metadata['userId'],
    #                     'userStripeAccount': retUserStripeAccount['userStripeAccount'],
    #                 },
    #             }
    #             await _websocket_clients.SendToUsersJson(jsonData, [data['metadata']['userId']])

    return web.Response(status=200)


def addRoutes():
    def GetPaymentLink(data, auth, websocket):
        data = lodash.extend_object({
            'recurringInterval': '',
            'recurringIntervalCount': 1,
            'quantity': 1,
        }, data)
        return _pay_stripe.StripePaymentLink(data['amountUSD'], data['userId'], data['title'],
            data['forId'], data['forType'], recurringInterval=data['recurringInterval'],
            recurringIntervalCount=data['recurringIntervalCount'], quantity = data['quantity'])
    _socket.add_route('StripeGetPaymentLink', GetPaymentLink)

    def GetAccountLink(data, auth, websocket):
        return _pay_stripe.StripeAccountLink(data['userId'])
    _socket.add_route('GetStripeAccountLink', GetAccountLink)

    # def SaveUserStripeAccount(data, auth, websocket):
    #     return _mongo_db_crud.Save('userStripeAccount', data['userStripeAccount'])
    # _socket.add_route('SaveUserStripeAccount', SaveUserStripeAccount)

    def GetUserStripeAccount(data, auth, websocket):
        # return _mongo_db_crud.Get('userStripeAccount', { 'userId': data['userId'] })
        # Just re-use stripe account link, which gets this info (as we want to check if complete too).
        return _pay_stripe.StripeAccountLink(data['userId'])
    _socket.add_route('GetUserStripeAccount', GetUserStripeAccount)

    def StripeWithdrawMoney(data, auth, websocket):
        return _pay_stripe.StripePayUser(data['userId'], data['amountUSD'])
    _socket.add_route('StripeWithdrawMoney', StripeWithdrawMoney)

addRoutes()

