# from fastapi import APIRouter

from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from shared_item import shared_item as _shared_item

# router = APIRouter()

def addRoutes():
    def SearchNear(data, auth, websocket):
        data = lodash.extend_object({
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
        }, data)
        # lngLat = [data['lng'], data['lat']]
        lngLat = data['lngLat']
        return _shared_item.SearchNear(lngLat, float(data['maxMeters']), data['title'], data['tags'],
            float(data['fundingRequired_min']), float(data['fundingRequired_max']), data['limit'], data['skip'],
            data['withOwnerUserId'])
    _socket.add_route('searchSharedItems', SearchNear)

    def Save(data, auth, websocket):
        return _shared_item.Save(data['sharedItem'])
    _socket.add_route('saveSharedItem', Save)

    def Remove(data, auth, websocket):
        return _mongo_db_crud.RemoveById('sharedItem', data['id'])
    _socket.add_route('removeSharedItem', Remove)

addRoutes()
