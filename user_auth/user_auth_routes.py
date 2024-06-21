# from fastapi import APIRouter
import date_time
from common import route_parse as _route_parse
from common import socket as _socket
from user_auth import user_auth as _user_auth
from user_auth import user as _user

from neighborhood import user_neighborhood as _user_neighborhood
from event import user_feedback as _user_feedback
from insight import user_insight as _user_insight

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
        if 'id' in data:
            data['userId'] = data['id']
        user = _user_auth.getById(data['userId'])
        ret = { 'valid': 1, 'message': '', 'user': user }
        ret = _route_parse.formatRet(data, ret)
        return ret
    _socket.add_route('getUserById', GetUserById)

    def GetUserByUsername(data, auth, websocket):
        user = _user_auth.getByUsername(data['username'])
        ret = { 'valid': 1, 'message': '', 'user': user }
        ret = _route_parse.formatRet(data, ret)
        return ret
    _socket.add_route('getUserByUsername', GetUserByUsername)

    def GetUserSession(data, auth, websocket):
        ret = _user_auth.getSession(data['userId'], data['sessionId'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                ret['user']['roles'] = ",".join(ret['user']['roles'])
            if 'withCheckUserFeedback' in data and data['withCheckUserFeedback']:
                ret['checkUserFeedback'] = _user_feedback.CheckAskForFeedback(data['userId'])
            _user_insight.Save({ 'userId': data['userId'], 'lastActiveAt': date_time.now_string() })
        return ret
    _socket.add_route('getUserSession', GetUserSession)

    def Login(data, auth, websocket):
        ret = _user_auth.login(data['email'], data['password'])
        if ret['valid']:
            # Join (to string) any nested fields for C# typings..
            if 'roles' in ret['user']:
                # del ret['user']['roles']
                ret['user']['roles'] = ",".join(ret['user']['roles'])
            if 'withUserNeighborhoods' in data and data['withUserNeighborhoods']:
                ret['userNeighborhoods'] = _user_neighborhood.Search(stringKeyVals = { 'userId': ret['user']['_id'], },
                    withNeighborhoods = 1)['userNeighborhoods']
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

    def SendPhoneVerificationCode(data, auth, websocket):
        return _user.SendPhoneVerificationCode(data['userId'], data['phoneNumber'])
    _socket.add_route('SendPhoneVerificationCode', SendPhoneVerificationCode)

    def VerifyPhone(data, auth, websocket):
        return _user.VerifyPhone(data['userId'], data['phoneNumberVerificationKey'])
    _socket.add_route('VerifyPhone', VerifyPhone)

addRoutes()
