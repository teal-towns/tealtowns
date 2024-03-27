import re
import stripe

import ml_config
_config = ml_config.get_config()

def StripePaymentLink(amountUSD: float, userId: str, title: str, forId: str, forType: str,
    recurringInterval: str = '', recurringIntervalCount: int = 1):
    ret = { 'valid': 1, 'message': '', 'url': '', 'priceId': '', }
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
