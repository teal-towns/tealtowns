from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
# import lodash

def addRoutes():
    def Save(data, auth, websocket):
        return _mongo_db_crud.Save('userAvailability', data['userAvailability'], checkGetKey = 'username')
    _socket.add_route('SaveUserAvailability', Save)

addRoutes()
