import hashlib
import re
import urllib

import lodash
import ml_config
import mongo_db
import notifications

_config = ml_config.get_config()

def encrypt_password(password, salt = 'K4L1Y08Rmx39SIvO'):
    salt = bytes(salt, 'utf-8')
    return hashlib.scrypt(bytes(password, 'utf-8'), salt = salt, n = 2, r = 8, p = 1)

def check_encrypted_password(password, hashed):
    if encrypt_password(password) == hashed:
        return True
    return False

def getUserFields():
    return {
        'email': True,
        'firstName': True,
        'lastName': True,
        'status': True,
        'roles': True,
        'username': True,
        'createdAt': True,
        'updatedAt': True,
    }

def checkEmail(email, fields=None):
    ret = { 'user': {}, 'msg': '' }
    fields = fields if fields is not None else {
        'email': True
    }
    email = email.lower()
    query = {
        'email': email,
        'status': 'member'
    }
    ret['user'] = mongo_db.find_one('user', query, fields=fields)['item']
    return ret

def getByEmail(email, fields=None):
    fields = fields if fields is not None else getUserFields()
    email = email.lower()
    query = {
        'email': email
    }
    user = mongo_db.find_one('user', query, fields=fields)['item']
    return user

def getById(userId, fields=None):
    fields = fields if fields is not None else getUserFields()
    query = {
        '_id': mongo_db.to_object_id(userId)
    }
    user = mongo_db.find_one('user', query, fields=fields)['item']
    return user

def getByUsername(username, fields=None):
    fields = fields if fields is not None else getUserFields()
    username = username.lower()
    query = {
        'username': username
    }
    user = mongo_db.find_one('user', query, fields=fields)['item']
    return user

def getByIds(userIds, fields=None):
    ret = { 'users': [], 'msg': '' }
    fields = fields if fields is not None else getUserFields()
    objectIds = []
    for userId in userIds:
        objectIds.append(mongo_db.to_object_id(userId))
    query = {
        '_id': {
            '$in': objectIds
        }
    }
    ret['users'] = mongo_db.find('user', query, fields=fields)['items']
    return ret

def signup(email, password, firstName, lastName, roles=[''], autoMember=1):
    global _config

    ret = { 'valid': 0, 'msg': '' }
    email = email.lower()
    user = checkEmail(email)['user']
    if not user:
        # Email verification is causing issues (not getting delivered, especially
        # to hotmail) so skip.
        status = 'guest'
        if autoMember:
            status = 'member'
        emailVerifyKey = lodash.random_string(6)
        query = {
            'email': email
        }
        mutation = {
            '$set': {
                'password': encrypt_password(password),
                'firstName': firstName,
                'lastName': lastName,
                'passwordResetKey': lodash.random_string(6),
                'status': status,
                'roles': roles,
                'emailVerificationKey': emailVerifyKey,
                'emailVerified': 0
            }
        }
        if autoMember:
            # Create unique username
            username = createUsername(firstName, lastName)['username']
            mutation['$set']['username'] = username

        result = mongo_db.update_one('user', query, mutation, upsert=True)
        if result:
            subject = 'Email Verification'
            url = _config['web_server']['urls']['base'] + '/email-verify?email=' + \
                urllib.parse.quote_plus(email) + '&key=' + emailVerifyKey
            body = 'Enter ' + emailVerifyKey + ' at ' + url + ' to verify your email.'
            notifications.send_all(subject, body, email)
            ret['valid'] = 1

            if autoMember:
                user = getById(result['upserted_id'])
                retSess = updateSession(user['_id'])
                if 'sessionId' in retSess:
                    user['sessionId'] = retSess['sessionId']
                    ret['user'] = user
                    ret['valid'] = 1
    else:
        ret['msg'] = "Email already in use."
    return ret

def login(emailOrUsername, password):
    ret = { 'valid': 0, 'msg': '', 'user': {} }
    # Want to get user in case valid password (avoid another database look up).
    # But also need password to check.
    fields = getUserFields()
    fields['password'] = True
    user = getByEmail(emailOrUsername, fields=fields)
    if user and user['status'] != 'member':
        ret['msg'] = "Email verification required to log in"
    if user is None:
        user = getByUsername(emailOrUsername, fields=fields)
        if user and user['status'] != 'member':
            ret['msg'] = "Email verification required to log in"
    if user and user['status'] == 'member':
        if check_encrypted_password(password, user['password']):
            retSess = updateSession(user['_id'])
            if 'sessionId' in retSess:
                user['sessionId'] = retSess['sessionId']
                del user['password']
                ret['user'] = user
                ret['valid'] = 1
            else:
                ret['msg'] = "Session error, please contact support"
        else:
            ret['msg'] = "Invalid password"
    elif not user:
        ret['msg'] = "No user with that email or username"
    return ret

def logout(userId, sessionId=""):
    ret = { 'valid': 0, 'msg': '' }

    # Handle permissions in routing - need to check on almost all calls, not just
    # logout.
    # # First need to get session (do not allow logout by non-logged in user).
    # retUser = getSession(userId, sessionId)
    # if '_id' in retUser['user']:
    query = {
        '_id': mongo_db.to_object_id(userId)
    }
    mutation = {
        # '$pull': {
        #     'sessionIds': sessionId
        # }
        # Clear out ALL sessions on logout.
        '$set': {
            'sessionIds': []
        }
    }
    result = mongo_db.update_one('user', query, mutation)
    if result:
        ret['valid'] = 1
    return ret

def updateSession(userId):
    ret = { 'valid': 0, 'msg': '' }
    sessionId = lodash.random_string(24)
    query = {
        '_id': mongo_db.to_object_id(userId)
    }
    mutation = {
        '$push': {
            'sessionIds': sessionId
        }
    }
    result = mongo_db.update_one('user', query, mutation)
    if result:
        ret['valid'] = 1
        ret['sessionId'] = sessionId
    return ret

# Check if already logged in.
def getSession(userId, sessionId):
    ret = { 'valid': 0, 'msg': '', 'user': {} }
    query = {
        '_id': mongo_db.to_object_id(userId),
        'sessionIds': {
            '$in': [
                sessionId
            ]
        }
    }
    fields = getUserFields()
    user = mongo_db.find_one('user', query, fields=fields)['item']
    if user is not None and '_id' in user:
        ret['user'] = user
        ret['valid'] = 1
        ret['user']['sessionId'] = sessionId
    return ret

def forgotPassword(email):
    global _config

    ret = { 'valid': 0, 'msg': '' }
    user = getByEmail(email)
    if user:
        resetKey = lodash.random_string(6)
        query = {
            '_id': mongo_db.to_object_id(user['_id'])
        }
        mutation = {
            '$set': {
                'passwordResetKey': resetKey
            }
        }
        result = mongo_db.update_one('user', query, mutation)
        if result:
            subject = 'Password Reset'
            url = _config['web_server']['urls']['base'] + '/password-reset?key=' + resetKey + \
                '&email=' + urllib.parse.quote_plus(email)
            body = 'Enter ' + resetKey + ' at ' + url + ' to reset your password.'
            notifications.send_all(subject, body, email)
            ret['valid'] = 1
    return ret

def passwordReset(email, passwordResetKey, newPassword):
    ret = { 'valid': 0, 'user': {}, 'msg': '' }
    email = email.lower()
    query = {
        'email': email,
        'passwordResetKey': passwordResetKey
    }
    fields = getUserFields()
    user = mongo_db.find_one('user', query, fields=fields)['item']
    if user:
        query = {
            '_id': mongo_db.to_object_id(user['_id'])
        }
        mutation = {
            '$set': {
                'password': encrypt_password(newPassword),
                # Change password reset key so can not be used again.
                'passwordResetKey': lodash.random_string(6)
            }
        }
        result = mongo_db.update_one('user', query, mutation)
        if result:
            retSess = updateSession(user['_id'])
            if 'sessionId' in retSess:
                user['sessionId'] = retSess['sessionId']
                ret['user'] = user
                ret['valid'] = 1
    else:
        ret['msg'] = 'Email or password reset key not found.'

    return ret

def emailVerify(email, verifyKey):
    ret = { 'valid': 0, 'msg': '', 'user': {} }
    email = email.lower()
    query = {
        'email': email,
        'emailVerificationKey': verifyKey
    }
    fields = getUserFields()
    user = mongo_db.find_one('user', query, fields=fields)['item']
    if user:
        # Create unique username
        username = createUsername(user['firstName'], user['lastName'])['username']
        query = {
            '_id': mongo_db.to_object_id(user['_id'])
        }
        mutation = {
            '$set': {
                'emailVerificationKey': lodash.random_string(6),
                'emailVerified': 1,
                'status': 'member',
                'username': username
            }
        }
        result = mongo_db.update_one('user', query, mutation)
        if result:
            retSess = updateSession(user['_id'])
            if 'sessionId' in retSess:
                user['sessionId'] = retSess['sessionId']
                ret['user'] = user
                ret['valid'] = 1
    return ret

def createUsername(firstName, lastName, maxNameChars=6):
    ret = { 'username': '', 'msg': '' }
    # Remove all non letters, go to lowercase, and combine first and last name
    # then cut at max length to make a username.
    username = (firstName + lastName).lower()
    regex = re.compile('[^a-zA-Z]')
    username = regex.sub('', username)
    if len(username) > maxNameChars:
        username = username[slice(0, maxNameChars)]
    # Check database for existing username and increment counter suffix until have
    # a unique one.
    query = {
        'username': {
            '$regex': '^' + username
        }
    }
    fields = {
        'username': True
    }
    users = mongo_db.find('user', query, fields=fields)['items']
    if len(users) < 1:
        usernameFinal = username
    else:
        existingUsernames = list(map(lambda item: item['username'], users))
        usernameFinal = None
        usernameCheck = username
        countSuffix = 0
        while usernameFinal is None:
            if usernameCheck not in existingUsernames:
                usernameFinal = usernameCheck
            else:
                countSuffix += 1
                usernameCheck = username + str(countSuffix)

    ret['username'] = usernameFinal
    return ret

def updateFirstLastName(user, firstName, lastName):
    ret = { 'valid': 0, 'msg': '' } 
    query = {
            '_id': mongo_db.to_object_id(user['_id'])
        }

    mutation = {
            '$set': {
                'firstName': firstName,
                'lastName': lastName,
            }
        }
    result = mongo_db.update_one('user', query, mutation)
    if result:
        retSess = updateSession(user['_id'])
        if 'sessionId' in retSess:
            user['sessionId'] = retSess['sessionId']
            ret['user'] = mongo_db.find_one('user', query, fields = getUserFields())['item']
            ret['valid'] = 1
    else:
        ret['msg'] = 'updateFirstLastName error'
    return ret