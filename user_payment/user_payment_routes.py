from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from event import user_event as _user_event
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
            'withForLink': 1,
            'stringKeyVals': {},
        }, data)
        ret = _mongo_db_crud.Search('userPayment', stringKeyVals = data['stringKeyVals'],
            sortKeys = data['sortKeys'], limit = data['limit'], skip = data['skip'])
        if data['withForLink']:
            ret['userPayments'] = _user_payment.AddForLinks(ret['userPayments'])
        return ret
    _socket.add_route('SearchUserPayments', SearchUserPayments)

    def SearchUserPaymentSubscriptions(data, auth, websocket):
        data = lodash.extend_object({
            'limit': 25,
            'skip': 0,
            'sortKeys': '-createdAt',
            'withForLink': 1,
            'stringKeyVals': {},
        }, data)
        ret = _mongo_db_crud.Search('userPaymentSubscription', stringKeyVals = data['stringKeyVals'],
            sortKeys = data['sortKeys'], limit = data['limit'], skip = data['skip'])
        if data['withForLink']:
            ret['userPaymentSubscriptions'] = _user_payment.AddForLinks(ret['userPaymentSubscriptions'])
        return ret
    _socket.add_route('SearchUserPaymentSubscriptions', SearchUserPaymentSubscriptions)

    def CancelSubscription(data, auth, websocket):
        return _user_payment.CancelSubscription(data['userPaymentSubscriptionId'])
    _socket.add_route('CancelUserPaymentSubscription', CancelSubscription)

addRoutes()
