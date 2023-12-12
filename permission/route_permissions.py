from permission import permission_user

def Allowed(route, auth, data):
    msgId = data['_msgId'] if '_msgId' in data else ''
    ret = { 'valid': 1, 'msg': '', '_msgId': msgId }

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
        "removeSharedItem",
        "saveSharedItem",
        "saveUser",
    ]

    admin = [
        "removeBlog",
        "saveBlog",
    ]
    if route in perms or route in userIdRequired or route in admin:
        if len(auth['userId']) == 0:
            ret['valid'] = 0
            ret['msg'] = "Empty user id."
            return ret

    if route in perms or route in admin:
        allowed = 0
        if "_" in auth['userId']:
            ret['valid'] = 0
            ret['msg'] = "Invalid user id"
            return ret

        if permission_user.LoggedIn(auth['userId'], auth['sessionId']):
            allowed = 1

        if not allowed:
            ret['valid'] = 0
            ret['msg'] = "Permission denied"
            return ret

    if route in admin:
        if permission_user.IsAdmin(auth['userId']):
            allowed = 1
        else:
            ret['valid'] = 0
            ret['msg'] = "Admin privileges required"
            return ret

    return ret
