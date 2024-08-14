from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'userId': '',
        'username': '',
        'interests': [],
    }

def AddDefault():
    _stubs_data.AddToNameMap('userInterest', GetDefault)
