from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'userId': '',
        'username': '',
        'lastActiveAt': _stubs_data.RandomDateTime(),
        'firstEventSignUpAt': _stubs_data.RandomDateTime(),
        'firstNeighborhoodJoinAt': _stubs_data.RandomDateTime(),
        'ambassadorSignUpStepsAt': {
            'userNeighborhoodSave': _stubs_data.RandomDateTime(),
        },
    }

def AddDefault():
    _stubs_data.AddToNameMap('userInsight', GetDefault)
