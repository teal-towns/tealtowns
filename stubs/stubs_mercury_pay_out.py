import random

from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'accountKey': 'MercuryEndUserFunds',
        'recipientKey': 'MercuryUserRevenue',
        'amountUSD': round(random.uniform(0.1, 100), 2),
        'forId': _stubs_data.RandomString(6),
        'forType': _stubs_data.RandomString(6),
        'paidOut': 0,
    }

def AddDefault():
    _stubs_data.AddToNameMap('mercuryPayOut', GetDefault)
