from common import socket as _socket
from user_payment import user_payment as _user_payment

def addRoutes():
    def GetUserMoneyAndPending(data, auth, websocket):
        return _user_payment.GetUserMoneyAndPending(data['userId'])
    _socket.add_route('GetUserMoneyAndPending', GetUserMoneyAndPending)

addRoutes()
