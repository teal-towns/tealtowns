import random

from stubs import stubs_data as _stubs_data

def GetDefault():
    return {
        'userId': '',
        'username': '',
        'neighborhoodUName': _stubs_data.RandomWord(),
        'status': random.choice(['deafult', '']),
        'roles': [],
        'vision': '',
        'motivations': [],
    }

def AddDefault():
    _stubs_data.AddToNameMap('userNeighborhood', GetDefault)
