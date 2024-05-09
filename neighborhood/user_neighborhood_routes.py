from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from neighborhood import user_neighborhood as _user_neighborhood

def addRoutes():

    def Save(data, auth, websocket):
        if 'removeDefault' in data and data['removeDefault']:
            # First remove any existing defaults.
            _user_neighborhood.SetAllStatus(data['userNeighborhood']['userId'], '')
        return _mongo_db_crud.Save('userNeighborhood', data['userNeighborhood'])
    _socket.add_route('SaveUserNeighborhood', Save)

    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'userId': '',
            'status': '',
            'limit': 25,
            'skip': 0,
            'withNeighborhoods': 0,
        }, data)
        return _user_neighborhood.Search(
            stringKeyVals = { 'userId': data['userId'], 'status': data['status'], },
            limit = data['limit'], skip = data['skip'],
            withNeighborhoods = data['withNeighborhoods'])
    _socket.add_route('SearchUserNeighborhoods', Search)

addRoutes()
