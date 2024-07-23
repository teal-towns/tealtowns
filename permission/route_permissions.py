from permission import permission_user

def Allowed(route, auth, data):
    messageId = data['_messageId'] if '_messageId' in data else ''
    ret = { 'valid': 1, 'message': '', '_messageId': messageId }

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

    byRoute = {
        'SaveUserRole': { 'roles': ['editUser'] },
        'SaveIcebreaker': { 'roles': ['tealtownsTeam'] },
        'HijackLogin': { 'roles': ['hijackUser'] },
    }

    if route in perms or route in userIdRequired or route in admin:
        if len(auth['userId']) == 0:
            ret['valid'] = 0
            ret['message'] = "Empty user id."
            return ret

    if route in perms or route in admin:
        allowed = 0
        if "_" in auth['userId']:
            ret['valid'] = 0
            ret['message'] = "Invalid user id"
            return ret

        if permission_user.LoggedIn(auth['userId'], auth['sessionId']):
            allowed = 1

        if not allowed:
            ret['valid'] = 0
            ret['message'] = "Permission denied"
            return ret

    if route in admin:
        if permission_user.IsAdmin(auth['userId']):
            allowed = 1
        else:
            ret['valid'] = 0
            ret['message'] = "Admin privileges required"
            return ret
    
    if route in byRoute:
        if len(auth['userId']) == 0 or "_" in auth['userId'] or \
            not permission_user.LoggedIn(auth['userId'], auth['sessionId']):
            ret['valid'] = 0
            ret['message'] = "Permission denied"
            return ret
        if 'roles' in byRoute[route]:
            for role in byRoute[route]['roles']:
                if not permission_user.HasRole(auth['userId'], role):
                    ret['valid'] = 0
                    ret['message'] = role + " user role required"
                    return ret

    return ret
