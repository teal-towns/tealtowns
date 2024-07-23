from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from user_auth import user_auth as _user_auth
from user_auth import user as _user
import lodash

def addRoutes():
    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'firstName': '',
            'lastName': '',
            'email': '',
            'limit': 25,
            'skip': 0,
            'sortKeys': '-createdAt',
        }, data)
        stringKeyVals = { 'firstName': data['firstName'], 'lastName': data['lastName'], 'email': data['email'], }
        fields = _user_auth.getUserFields()
        return _mongo_db_crud.Search('user', stringKeyVals = stringKeyVals, limit = data['limit'],
            skip = data['skip'], fields = fields, sortKeys = data['sortKeys'])
    _socket.add_route('SearchUsers', Search)

    def SaveRole(data, auth, websocket):
        return _user.SaveUser(data['user'], ['roles'])
    _socket.add_route('SaveUserRole', SaveRole)

    def GetUserJoinCollections(data, auth, websocket):
        data = lodash.extend_object({
            'userId': '',
            'username': '',
        }, data)
        return _user.GetJoinCollections(data['userId'], data['username'])
    _socket.add_route('GetUserJoinCollections', GetUserJoinCollections)

    def HijackLogin(data, auth, websocket):
        return _user.HijackLogin(data['superUserId'], data['usernameToHijack'])
    _socket.add_route('HijackLogin', HijackLogin)

addRoutes()
