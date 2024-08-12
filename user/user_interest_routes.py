from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
# import lodash

def addRoutes():
    def Save(data, auth, websocket):
        return _mongo_db_crud.Save('userInterest', data['userInterest'], checkGetKey = 'username')
    _socket.add_route('SaveUserInterest', Save)

addRoutes()
