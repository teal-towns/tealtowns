from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'uName': _stubs_data.RandomWord(),
        'location': _stubs_data.RandomLocation(),
        'timezone': 'UTC',
        'title': _stubs_data.RandomWord(),
    }

def AddDefault():
    _stubs_data.AddToNameMap('neighborhood', GetDefault)
