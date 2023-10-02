import json
import time

import ml_config

from image import file_upload as _file_upload
from image import image as _image
from permission import permission_user
import user_auth
import websocket_clients as _websocket_clients

config = ml_config.get_config()

def routeIt(route, data, auth):
    msgId = data['_msgId'] if '_msgId' in data else ''
    ret = { 'valid': '0', 'msg': '', '_msgId': msgId }

    # Check permissions.
    perms = [
        # Save is more dangerous than get; for performance / speed, allow most get calls, unless
        # it returns sensitive information.
        # All allowed get
        # Sensitive, or performance intenstive get
        # [none yet]
        # Save
        "logout",
        "saveImage",
    ]

    userIdRequired = [
    ]

    admin = [
    ]
    if route in perms or route in userIdRequired or route in admin:
        if len(auth['userId']) == 0:
            ret['msg'] = "Empty user id."
            return ret

    if route in perms or route in admin:
        allowed = 0
        if "_" in auth['userId']:
            ret['msg'] = "Invalid user id"
            return ret

        if permission_user.LoggedIn(auth['userId'], auth['sessionId']):
            allowed = 1

        if not allowed:
            ret['msg'] = "Permission denied"
            return ret

    if route in admin:
        if permission_user.IsAdmin(auth['userId']):
            allowed = 1
        else:
            ret['msg'] = "Admin privileges required"
            return ret

    # We must support at least 2 versions since frontend (mobile apps) will
    # not instant update in sync with breaking changes on backend. BUT to keep
    # code clean, force update for earlier versions.
    allowedVersions = ['0.0.0', '0.0.1']

    # if route == 'route1':
    #     ret = route1(data)
    # elif route == 'route2':
    #     ret = { 'hello': 'route 2' }

    if route == 'getAllowedVersions':
        ret = { 'valid': '1', 'msg': '', 'versions': allowedVersions }
    elif route == 'ping':
        ret = { 'valid': '1', 'msg': '' }

    elif route == 'signup':
        roles = data['roles'] if 'roles' in data else ['student']
        ret = user_auth.signup(data['email'], data['password'], data['firstName'], data['lastName'],
            roles)
        if ret['valid'] and 'user' in ret and ret['user']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
            ret['_socketAdd'] = { 'userId': ret['user']['_id'] }

    elif route == 'emailVerify':
        ret = user_auth.emailVerify(data['email'], data['emailVerificationKey'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
            ret['_socketAdd'] = { 'userId': ret['user']['_id'] }
    elif route == 'passwordReset':
        ret = user_auth.passwordReset(data['email'], data['passwordResetKey'], data['password'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
            ret['_socketAdd'] = { 'userId': ret['user']['_id'] }

    elif route == 'login':
        ret = user_auth.login(data['email'], data['password'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
            ret['_socketAdd'] = { 'userId': ret['user']['_id'] }

    elif route == 'forgotPassword':
        ret = user_auth.forgotPassword(data['email'])

    elif route == 'getUserSession':
        ret = user_auth.getSession(data['userId'], data['sessionId'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                ret['user']['roles'] = ",".join(ret['user']['roles'])
            ret['_socketAdd'] = { 'userId': ret['user']['_id'] }

    elif route == 'logout':
        ret = user_auth.logout(data['userId'], data['sessionId'])
        # Logout all sockets for this user.
        if '_socketSendSeparate' not in ret:
            ret['_socketSendSeparate'] = []
        ret['_socketSendSeparate'].append({
            'userIds': [ data['userId'] ],
            'route': 'onLogout',
            'data': {
                'valid': '1',
                'msg': ''
            }
        })

        ret['_socketRemove'] = { 'userId': data['userId'] }

    elif route == "getImages":
        title = data['title'] if 'title' in data else ''
        url = data['url'] if 'url' in data else ''
        userIdCreator = data['userIdCreator'] if 'userIdCreator' in data else ''
        ret = _image.Get(title, url, userIdCreator, data['limit'], data['skip'])
        ret = formatRet(data, ret)
    elif route == "saveImage":
        ret = _image.Save(data['image'])
        ret = formatRet(data, ret)
    elif route == "getImageData":
        imageDataString = _file_upload.GetImageData(data['image_url'])
        ret = { 'valid': '1', 'msg': '', 'image_url': data['image_url'],
            'image_data': imageDataString }

    elif route == "saveFileData":
        if data['fileType'] == 'image':
            saveToUserImages = data['saveToUserImages'] if 'saveToUserImages' in data else False
            maxSize = data['maxSize'] if 'maxSize' in data else 600
            ret = _file_upload.SaveImageData(data['fileData'], config['web_server']['urls']['base_server'],
                maxSize = maxSize, removeOriginalFile = 1)
            if ret['valid'] and saveToUserImages and len(auth['userId']) > 0:
                title = data['title'] if 'title' in data else ''
                if len(title) > 0:
                    userImage = { 'url': ret['url'], 'title': title, 'userIdCreator': auth['userId'] }
                    retUserImage = _image.Save(userImage)
                    ret['userImage'] = formatRet(data, retUserImage)
        else:
            ret = _file_upload.SaveFileData(data['fileData'], config['web_server']['urls']['base_server'], data['fileName'])
    elif route == "saveImageData":
        ret = _file_upload.SaveImageData(data['fileData'], config['web_server']['urls']['base_server'], removeOriginalFile = 1)

    elif route == "getUserById":
        user = user_auth.getById(data['userId'])
        ret['valid'] = '1'
        ret['user'] = user
        ret = formatRet(data, ret)

    ret['_msgId'] = msgId
    return ret

# def route1(data):
#     ret = { 'key': 'whatup route 1' }
#     return ret

# def route2(data):
#     ret = { 'hello': 'route 2' }
#     return ret

def formatRet(data, ret, arrayJoinKeys=[], arrayJoinDelimiter=","):
    stringKeys = data['string_keys'] if 'string_keys' in data else 1
    if stringKeys:
        ret = objectToStringKeys(ret, arrayJoinKeys, arrayJoinDelimiter)
    return ret

def objectToStringKeys(obj, arrayJoinKeys=[], arrayJoinDelimiter=","):
    if isinstance(obj, list):
        for item in obj:
            item = objectToStringKeys(item, arrayJoinKeys, arrayJoinDelimiter)
    elif isinstance(obj, dict):
        for key in obj:
            if isinstance(obj[key], list):
                if key in arrayJoinKeys:
                    obj[key] = arrayJoinDelimiter.join(obj[key])
                else:
                    obj[key] = objectToStringKeys(obj[key], arrayJoinKeys, arrayJoinDelimiter)
            elif isinstance(obj[key], dict):
                obj[key] = objectToStringKeys(obj[key], arrayJoinKeys, arrayJoinDelimiter)
            else:
                obj[key] = str(obj[key])
    else:
        obj = str(obj)
    return obj

def GetTimestamp():
    return int(time.time())

def AddTimestamp(ret):
    ret['timestamp'] = GetTimestamp()
    return ret
