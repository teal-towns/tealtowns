import random

from stubs import stubs_data as _stubs_data

_default = {
    'uName': _stubs_data.RandomString(6),
    'type': random.choice(['', 'sharedMeal']),
    'title': _stubs_data.RandomWords(2),
    'description': _stubs_data.RandomWords(10),
    'dayOfWeek': random.randint(0, 6),
    'startTime': _stubs_data.RandomTime(),
    'endTime': _stubs_data.RandomTime(),
    'timezone': 'America/Los_Angeles',
    'location': _stubs_data.RandomLocation(),
    'adminUserIds': [],
    'hostGroupSizeDefault': random.randint(4, 10),
    'hostMoneyPerPersonUSD': random.randint(4, 10),
    'priceUSD': random.randint(10, 20),
    'rsvpDeadlineHours': random.randint(24, 72),
    'imageUrls': [ _stubs_data.RandomImageUrl() ],
    'archived': 0,
}

def AddDefault():
    _stubs_data.AddToNameMap('weeklyEvent', _default)
