# import random

from stubs import stubs_data as _stubs_data

_default = {
    'weeklyEventId': _stubs_data.RandomString(6),
    'start': _stubs_data.RandomTime(),
}

def AddDefault():
    _stubs_data.AddToNameMap('event', _default)
