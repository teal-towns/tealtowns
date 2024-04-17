import random

from stubs import stubs_data as _stubs_data

_default = {
    'uName': _stubs_data.RandomString(6),
    'title': _stubs_data.RandomWords(2),
    'description': _stubs_data.RandomWords(10),
    'imageUrls': [ _stubs_data.RandomImageUrl() ],
    'currentOwnerUserId': '',
    'currentPurchaserUserId': '',
    'tags': [],
    'location': _stubs_data.RandomLocation(),
    'bought': random.choice([0, 1]),
    'originalPrice': random.randint(10, 10000),
    'currentPrice': random.randint(10, 10000),
    'currency': 'USD',
    'generation': random.randint(0, 5),
    'currentGenerationStart': '',
    'monthsToPayBack': random.randint(1, 36),
    'maintenancePerYear': random.randint(10, 1000),
    'maintenanceAvailable': random.randint(0, 1000),
    'minOwners': random.randint(1, 5),
    'maxOwners': random.randint(5, 25),
    'maxMeters': random.choice([500, 1500, 3500, 8000]),
    'status': 'available',
    'pledgedOwners': 0,
    'fundingRequired': 0,
}

def AddDefault():
    _stubs_data.AddToNameMap('sharedItem', _default)

# def GetDefault():
#     return _default
