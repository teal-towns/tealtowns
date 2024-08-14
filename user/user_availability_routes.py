from common import socket as _socket
from user import user_availability as _user_availability

def addRoutes():
    def Save(data, auth, websocket):
        return _user_availability.Save(data['userAvailability'])
    _socket.add_route('SaveUserAvailability', Save)

addRoutes()
