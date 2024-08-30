from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'userId': '',
        'username': '',
        'availableTimesByDay': [],
    }

def AddDefault():
    _stubs_data.AddToNameMap('userAvailability', GetDefault)
