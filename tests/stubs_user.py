# import random

import mongo_db
import user_auth as _user_auth

_users = [
    {
        'email': 'bob@earthshot.eco',
        'password': 'pass12',
        'firstName': 'Bob',
        'lastName': 'Johnson',
        'roles': ['']
    },
    {
        'email': 'alice@earthshot.eco',
        'password': 'pass23',
        'firstName': 'Alice',
        'lastName': 'Souza',
        'roles': ['']
    }
]


def GetInvestorUser():
  return {
    'email': 'sarah@vc.eco',
    'password': 'pass23',
    'firstName': 'Sarah',
    'lastName': 'Investor',
    'roles': ['investor']
  }


# TODO treating a proponent as a user without role is not great. We should improve this
def GetProponentUser():
  return {
    'email': 'andrew@proponent.ngo',
    'password': 'pass23',
    'firstName': 'Andrew',
    'lastName': 'Proponent',
    'roles': ['']
  }

def GetAll():
    global _users
    return _users

def CreateUser(user):
    return _user_auth.signup(user['email'], user['password'], user['firstName'], user['lastName'], user['roles'])

def DeleteAll():
    mongo_db.delete_many('user', {})
