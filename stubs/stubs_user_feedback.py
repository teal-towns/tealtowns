import random

from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'userId': '',
        'forType': 'event',
        'forId': '',
        'attended': random.choice(['yes', 'no']),
        'stars': random.randint(1, 5),
        'willJoinNextWeek': random.choice(['yes', 'no', 'futureWeek']),
        'willInvite': random.choice(['no', 'willMeetNewNeighbor']),
        'invites': [],
    }

def AddDefault():
    _stubs_data.AddToNameMap('userFeedback', GetDefault)
