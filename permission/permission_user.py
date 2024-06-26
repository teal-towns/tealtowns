import mongo_db
from user_auth import user_auth

def LoggedIn(userId, sessionId):
    ret = user_auth.getSession(userId, sessionId)
    if ret['user'] and ret['user']['_id']:
        return True
    return False

def IsAdmin(userId):
    return HasRole(userId, 'admin')

def HasRole(userId, role):
    user = user_auth.getById(userId)
    if user and user['_id'] and role in user['roles']:
        return True
    return False
