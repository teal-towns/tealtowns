from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'userId': '',
        'username': '',
        'interests': [],
        'hostInterests': [],
        'hostInterestsPending': [],
    }

def AddDefault():
    _stubs_data.AddToNameMap('userInterest', GetDefault)
