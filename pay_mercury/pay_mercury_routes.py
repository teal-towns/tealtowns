import lodash
from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket

def addRoutes():
    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'paidOut': '',
            'limit': 250,
            'skip': 0,
            'sortKeys': '-createdAt',
        }, data)
        equalsKeyVals = {}
        if len(data['paidOut']) > 0:
            equalsKeyVals['paidOut'] = int(data['paidOut'])
        return _mongo_db_crud.Search('mercuryPayOut', equalsKeyVals = equalsKeyVals,
            sortKeys = data['sortKeys'], limit = data['limit'], skip = data['skip'],)
    _socket.add_route('SearchMercuryPayOuts', Search)

addRoutes()