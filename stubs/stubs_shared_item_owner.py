import random

from shared_item import shared_item as _shared_item
from shared_item import shared_item_owner as _shared_item_owner
from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'generation': random.randint(0, 5),
        'monthlyPayment': random.uniform(0, 1000),
        'totalPaid': random.uniform(0, 1000),
        'totalOwed': random.uniform(0, 1000),
        'totalPaidBack': 0,
        'investorOnly': random.choice([0, 1]),
        'status': '',
        'stripeMonthlyPriceId': '',
    }

def AddDefault():
    _stubs_data.AddToNameMap('sharedItemOwner', GetDefault)
