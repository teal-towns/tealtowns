# import random

from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'weeklyEventId': _stubs_data.RandomString(6),
        'start': _stubs_data.RandomTime(),
        'end': _stubs_data.RandomTime(),
    }

def AddDefault():
    _stubs_data.AddToNameMap('event', GetDefault)
