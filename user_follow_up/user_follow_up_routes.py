from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash

def addRoutes():
    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'username': '',
            'neighborhoodUName': '',
            'forType': '',
            'limit': 250,
            'skip': 0,
        }, data)
        stringKeyVals = { 'username': data['username'], 'neighborhoodUName': data['neighborhoodUName'],
            'forType': data['forType'], }
        return _mongo_db_crud.Search('userFollowUp', stringKeyVals = stringKeyVals,
            limit = data['limit'], skip = data['skip'])
    _socket.add_route('SearchUserFollowUp', Search)

addRoutes()
