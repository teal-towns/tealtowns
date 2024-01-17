from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from shared_item import shared_item_owner as _shared_item_owner

def addRoutes():
    def Get(data, auth, websocket):
        data = lodash.extend_object({ 'generation': 1, 'withSharedItem': 0 }, data)
        return _shared_item_owner.Get(data['id'], data['sharedItemId'], data['userId'],
            int(data['generation']), int(data['withSharedItem']))
    _socket.add_route('getSharedItemOwner', Get)

    def GetById(data, auth, websocket):
        return _mongo_db_crud.GetById('sharedItemOwner', data['id'])
    _socket.add_route('getSharedItemOwnerById', GetById)

    def Save(data, auth, websocket):
        data['sharedItemOwner'] = lodash.pick(data['sharedItemOwner'], ['_id', 'createdAt', 'updatedAt',
            'sharedItemId', 'userId', 'monthlyPayment', 'totalPaid', 'totalOwed', 'generation', 'investorOnly',
            'status', 'stripeMonthlyPriceId'])
        return _shared_item_owner.Save(data['sharedItemOwner'])
    _socket.add_route('saveSharedItemOwner', Save)

    def RemoveById(data, auth, websocket):
        return _mongo_db_crud.RemoveById('sharedItemOwner', data['id'])
    _socket.add_route('removeSharedItemOwner', RemoveById)

addRoutes()
