# from fastapi import APIRouter

from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from shared_item import amazon_search as _amazon_search
from shared_item import shared_item as _shared_item
from shared_item import shared_item_payment as _shared_item_payment
from shared_item import shared_item_payment_math as _shared_item_payment_math
from user_payment import user_payment as _user_payment

# router = APIRouter()

def addRoutes():
    def SearchNear(data, auth, websocket):
        data = lodash.extend_object({
            'maxMeters': 1500,
            'title': '',
            'tags': [],
            # 'currentPrice_min': -1,
            # 'currentPrice_max': -1,
            'fundingRequired_min': -1,
            'fundingRequired_max': -1,
            'limit': 25,
            'skip': 0,
            # 'sortKey'
            'withOwnerUserId': '',
            'myType': '',
            'status': 'available',
            'currentOwnerUserId': '',
        }, data)
        # lngLat = [data['lng'], data['lat']]
        lngLat = data['lngLat']
        return _shared_item.SearchNear(lngLat, float(data['maxMeters']), data['title'], data['tags'],
            float(data['fundingRequired_min']), float(data['fundingRequired_max']), data['limit'], data['skip'],
            data['withOwnerUserId'], data['myType'], status = data['status'],
            currentOwnerUserId = data['currentOwnerUserId'])
    _socket.add_route('searchSharedItems', SearchNear)

    def Save(data, auth, websocket):
        return _shared_item.Save(data['sharedItem'])
    _socket.add_route('saveSharedItem', Save)

    def Remove(data, auth, websocket):
        return _mongo_db_crud.RemoveById('sharedItem', data['id'])
    _socket.add_route('removeSharedItem', Remove)

    def GetById(data, auth, websocket):
        data = lodash.extend_object({
            'withOwnerUserId': '',
        }, data)
        return _shared_item.GetById(data['id'], withOwnerUserId = data['withOwnerUserId'])
    _socket.add_route('getSharedItemById', GetById)

    def GetByUName(data, auth, websocket):
        data = lodash.extend_object({
            'withOwnerUserId': '',
        }, data)
        return _shared_item.GetById('', data['uName'], withOwnerUserId = data['withOwnerUserId'])
    _socket.add_route('GetSharedItemByUName', GetByUName)

    def GetSharedItemDownPaymentLink(data, auth, websocket):
        if data['checkAndUseBalance']:
            retMoney = _user_payment.GetUserMoneyAndPending(data['userId'])
            if retMoney['availableUSD'] >= data['amountUSD']:
                withoutFees = _shared_item_payment_math.RemoveFee(data['amountUSD'])
                return { 'valid': 1, 'message': '', 'haveBalance': 1, 'totalPaid': withoutFees }
        return _shared_item_payment.StripePaymentLinkDown(data['amountUSD'], data['sharedItemTitle'],
            data['sharedItemId'], data['userId'])
    _socket.add_route('GetSharedItemDownPaymentLink', GetSharedItemDownPaymentLink)

    def GetSharedItemMonthlyPaymentLink(data, auth, websocket):
        # Can not use balance for recurring payments.
        return _shared_item_payment.StripePaymentLinkMonthly(data['sharedItemOwnerId'])
    _socket.add_route('GetSharedItemMonthlyPaymentLink', GetSharedItemMonthlyPaymentLink)

    def AmazonSearch(data, auth, websocket):
        return _amazon_search.Search(data['search'])
    _socket.add_route('AmazonSearch', AmazonSearch)

addRoutes()
