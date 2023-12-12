# from fastapi import APIRouter

from common import route_parse as _route_parse
from common import socket as _socket
from user_auth import user_auth as _user_auth
from user_auth import user as _user

# router = APIRouter()

def addRoutes():
    def EmailVerify(data, auth, websocket):
        ret = _user_auth.emailVerify(data['email'], data['emailVerificationKey'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
        return ret
    _socket.add_route('emailVerify', EmailVerify)

    def ForgotPassword(data, auth, websocket):
        ret = _user_auth.forgotPassword(data['email'])
        return ret
    _socket.add_route('forgotPassword', ForgotPassword)

    def GetUserById(data, auth, websocket):
        user = _user_auth.getById(data['userId'])
        ret = { 'valid': 1, 'msg': '', 'user': user }
        ret = _route_parse.formatRet(data, ret)
        return ret
    _socket.add_route('getUserById', GetUserById)

    def GetUserSession(data, auth, websocket):
        ret = _user_auth.getSession(data['userId'], data['sessionId'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                ret['user']['roles'] = ",".join(ret['user']['roles'])
        return ret
    _socket.add_route('getUserSession', GetUserSession)

    def Login(data, auth, websocket):
        ret = _user_auth.login(data['email'], data['password'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
        return ret
    _socket.add_route('login', Login)

    def Logout(data, auth, websocket):
        ret = _user_auth.logout(data['userId'], data['sessionId'])
        return ret
    _socket.add_route('logout', Logout)

    def PasswordReset(data, auth, websocket):
        ret = _user_auth.passwordReset(data['email'], data['passwordResetKey'], data['password'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
        return ret
    _socket.add_route('passwordReset', PasswordReset)

    def Signup(data, auth, websocket):
        roles = data['roles'] if 'roles' in data else ['student']
        ret = _user_auth.signup(data['email'], data['password'], data['firstName'], data['lastName'],
            roles)
        if ret['valid'] and 'user' in ret and ret['user']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
        return ret
    _socket.add_route('signup', Signup)

    def Save(data, auth, websocket):
        return _user.SaveUser(data['user'])
    _socket.add_route('saveUser', Save)

addRoutes()
