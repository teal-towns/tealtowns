from aiohttp import web
import json
import stripe

import ml_config
_config = ml_config.get_config()

from common import socket as _socket
import websocket_clients as _websocket_clients
from shared_item import shared_item_payment as _shared_item_payment
from shared_item import shared_item_payment_math as _shared_item_payment_math
from user_payment import user_payment as _user_payment

def Routes(app, cors):
    resource = cors.add(app.router.add_resource('/web/stripe-webhooks'))
    cors.add(resource.add_route('POST', StripeWebhook))

# https://stripe.com/docs/testing
# https://stripe.com/docs/webhooks
# https://stripe.com/docs/api/checkout/sessions/object
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
                # Add deposit
                withoutPayFee = _shared_item_payment_math.RemoveFee(data['amount_total'] / 100, withCut = False)
                withoutFees = _shared_item_payment_math.RemoveFee(data['amount_total'] / 100)
                _user_payment.AddPayment(data['metadata']['userId'], withoutPayFee, 'sharedItem',
                    data['metadata']['sharedItemId'], 'complete', notes = 'Stripe down payment')

                # Need to extract from stripe object json format..
                data1 = {}
                for key in data['metadata']:
                    data1[key] = data['metadata'][key]
                data1['totalPaid'] = withoutFees
                jsonData = {
                    'route': 'StripePaymentComplete',
                    # 'data': data['metadata'],
                    'data': data1,
                }
                await _websocket_clients.SendToUsersJson(jsonData, [data['metadata']['userId']])
    elif event.type == 'checkout.session.async_payment_failed':
        data = event.data.object
        print ('checkout.session.async_payment_failed', data)
        # TODO

    # https://stripe.com/docs/api/payment_intents/object
    elif event.type == 'payment_intent.succeeded':
        data = event.data.object
        if data['status'] in ['succeeded', 'processing']:
            if 'userId' in data['metadata']:
                withoutPayFee = _shared_item_payment_math.RemoveFee(data['amount'] / 100, withCut = False)
                withoutFees = _shared_item_payment_math.RemoveFee(data['amount'] / 100)
                _user_payment.AddPayment(data['metadata']['userId'], withoutPayFee, 'sharedItemOwner',
                    data['metadata']['sharedItemOwnerId'], 'complete', notes = 'Stripe monthly payment')
                _shared_item_payment.MakeOwnerPayment(data['metadata']['sharedItemOwnerId'], withoutFees)

    elif event.type == 'payment_intent.payment_failed':
        # TODO
        pass

    return web.Response(status=200)
