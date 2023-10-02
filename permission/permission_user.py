import mongo_db
import user_auth

def LoggedIn(userId, sessionId):
    ret = user_auth.getSession(userId, sessionId)
    if ret['user'] and ret['user']['_id']:
        return True
    return False

def IsAdmin(userId):
    user = user_auth.getById(userId)
    if user and user['_id'] and 'admin' in user['roles']:
        return True
    return False
