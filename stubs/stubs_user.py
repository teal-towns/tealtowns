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
        'roles': [''],
        'username': 'bob',
    },
    {
        'email': 'alice@email.com',
        'password': 'pass23',
        'firstName': 'Alice',
        'lastName': 'Souza',
        'roles': [''],
        'username': 'alice',
    }
]

def GetDefault():
    return {
        'email': _stubs_data.RandomString() + '@email.com',
        'emailVerified': random.randint(0, 1),
        'password': _stubs_data.RandomString(),
        'firstName': _stubs_data.RandomWord(),
        'lastName': _stubs_data.RandomWord(),
        'roles': [''],
        'phoneNumber': _stubs_data.RandomPhone(),
        'phoneNumberVerified': random.randint(0, 1),
        'whatsappNumber': _stubs_data.RandomPhone(),
        'whatsappNumberVerified': random.randint(0, 1),
        'username': _stubs_data.RandomString().lower(),
    }

def AddDefault():
    _stubs_data.AddToNameMap('user', GetDefault)

def GetAll():
    global _users
    return _users

def CreateUser(user):
    return _user_auth.signup(user['email'], user['password'], user['firstName'], user['lastName'], user['roles'])

def DeleteAll():
    mongo_db.delete_many('user', {})
