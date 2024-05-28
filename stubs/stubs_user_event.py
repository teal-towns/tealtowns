import random

from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'eventId': '',
        'userId': '',
        'hostGroupSizeMax': random.randint(0, 10),
        'hostGroupSize': 0,
        'hostStatus': 'pending',
        'attendeeCountAsk': random.randint(1, 5),
        'attendeeCount': 0,
        'attendeeStatus': 'pending',
        'creditsEarned': 0,
        'creditsRedeemed': 0,
        'creditsPriceUSD': random.randint(10, 20),
        'eventEnd': _stubs_data.RandomTime(),
    }

def AddDefault():
    _stubs_data.AddToNameMap('userEvent', GetDefault)
