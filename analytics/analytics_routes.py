# import re

# from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from neighborhood import neighborhood as _neighborhood

def addRoutes():
    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'title': '',
            'location': {},
            'limit': 25,
            'skip': 0,
        }, data)
        return _neighborhood.SearchNear(stringKeyVals = { 'title': data['title'], },
            locationKeyVals = { 'location': data['location'], }, limit = data['limit'], skip = data['skip'])
    _socket.add_route('DisplayNeighborhoods', Search)

addRoutes()
