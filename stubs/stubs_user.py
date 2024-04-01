import random

import mongo_db
from stubs import stubs_data as _stubs_data
from user_auth import user_auth as _user_auth

_users = [
    {
        'email': 'bob@email.com',
        'password': 'pass12',
        'firstName': 'Bob',
        'lastName': 'Johnson',
        'roles': ['']
    },
    {
        'email': 'alice@email.com',
        'password': 'pass23',
        'firstName': 'Alice',
        'lastName': 'Souza',
        'roles': ['']
    }
]

_default = {
  'email': _stubs_data.RandomString() + '@email.com',
  'password': _stubs_data.RandomString(),
  'firstName': _stubs_data.RandomWord(),
  'lastName': _stubs_data.RandomWord(),
  'roles': [''],
  'phoneNumber': _stubs_data.RandomPhone(),
  'phoneNumberVerified': random.randint(0, 1),
}

def AddDefault():
    _stubs_data.AddToNameMap('user', _default)

# def GetDefault():
#     return _default

def GetAll():
    global _users
    return _users

def CreateUser(user):
    return _user_auth.signup(user['email'], user['password'], user['firstName'], user['lastName'], user['roles'])

def DeleteAll():
    mongo_db.delete_many('user', {})
