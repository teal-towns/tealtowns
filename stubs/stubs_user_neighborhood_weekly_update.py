import datetime
import random

import date_time
from stubs import stubs_data as _stubs_data

def GetDefault():
    start = _stubs_data.RandomDateTime()
    end = date_time.string(date_time.from_string(start) + datetime.timedelta(days = 7))
    return {
        'userId': '',
        'username': '',
        'neighborhoodUName': _stubs_data.RandomWord(),
        'start': start,
        'end': end,
        'inviteCount': random.randint(0, 20),
        'attendedCount': random.randint(0, 20),
    }

def AddDefault():
    _stubs_data.AddToNameMap('userNeighborhoodWeeklyUpdate', GetDefault)
