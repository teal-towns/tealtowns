from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from user_payment import user_payment as _user_payment

def addRoutes():
    def GetUserMoneyAndPending(data, auth, websocket):
        return _user_payment.GetUserMoneyAndPending(data['userId'])
    _socket.add_route('GetUserMoneyAndPending', GetUserMoneyAndPending)

    def SearchUserPayments(data, auth, websocket):
        data = lodash.extend_object({
            'limit': 25,
            'skip': 0,
            'sortKeys': '-createdAt',
        }, data)
        return _mongo_db_crud.Search('userPayment', sortKeys = data['sortKeys'],
            limit = data['limit'], skip = data['skip'])
    _socket.add_route('SearchUserPayments', SearchUserPayments)

    def SearchUserPaymentSubscriptions(data, auth, websocket):
        data = lodash.extend_object({
            'limit': 25,
            'skip': 0,
            'sortKeys': '-createdAt',
        }, data)
        return _mongo_db_crud.Search('userPaymentSubscription', sortKeys = data['sortKeys'],
            limit = data['limit'], skip = data['skip'])
    _socket.add_route('SearchUserPaymentSubscriptions', SearchUserPaymentSubscriptions)

addRoutes()
