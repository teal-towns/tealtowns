from common import math_polygon as _math_polygon
from common import mongo_db_crud as _mongo_db_crud
from shared_item import shared_item_owner as _shared_item_owner

def SearchNear(lngLat: list, maxMeters: float, title: str = '', tags: list = [], fundingRequired_min: float = -1,
    fundingRequired_max: float = -1, limit: int = 25, skip: int = 0, withOwnerUserId: str = ''):
    query = {
        'location': {
            '$nearSphere': {
                '$geometry': {
                    'type': 'Point',
                    'coordinates': lngLat,
                },
                '$maxDistance': maxMeters,
            }
        },
        'status': 'available',
    }
    minKeyVals = {}
    if fundingRequired_min > 0:
        minKeyVals['fundingRequired'] = fundingRequired_min
    maxKeyVals = {}
    if fundingRequired_max > 0:
        maxKeyVals['fundingRequired'] = fundingRequired_max
    ret = _mongo_db_crud.Search('sharedItem', {'title': title}, {'tags': tags},
        minKeyVals = minKeyVals, maxKeyVals = maxKeyVals, limit = limit, skip = skip, query = query)
    sharedItemIds = []
    sharedItemIndexMap = {}
    # Calculate distance
    # May also be able to use geoNear https://stackoverflow.com/questions/33864461/mongodb-print-distance-between-two-points
    for index, item in enumerate(ret['sharedItems']):
        ret['sharedItems'][index]['xDistanceKm'] = _math_polygon.Haversine(item['location']['coordinates'],
            lngLat, units = 'kilometers')
        sharedItemIds.append(item['_id'])
        sharedItemIndexMap[item['_id']] = index

    if len(sharedItemIds) > 0 and len(withOwnerUserId) > 0:
        listKeyVals = {'sharedItemId': sharedItemIds }
        stringKeyVals = {'userId': withOwnerUserId}
        sharedItemOwners = _mongo_db_crud.Search('sharedItemOwner', listKeyVals = listKeyVals, stringKeyVals = stringKeyVals)['sharedItemOwners']
        for owner in sharedItemOwners:
            index = sharedItemIndexMap[owner['sharedItemId']]
            # Check generation (ensure 1 above current)
            if owner['generation'] == ret['sharedItems'][index]['generation'] + 1:
                ret['sharedItems'][index]['sharedItemOwner_current'] = owner

    return ret

def Save(sharedItem: dict):
    ret = { 'valid': 1, 'message': '', 'sharedItem': {}, 'sharedItemOwner': {} }
    if 'pledgedOwners' not in sharedItem:
        sharedItem['pledgedOwners'] = 0
    if 'fundingRequired' not in sharedItem:
        sharedItem['fundingRequired'] = sharedItem['currentPrice']
    if 'currency' not in sharedItem:
        sharedItem['currency'] = 'USD'
    ret = _mongo_db_crud.Save('sharedItem', sharedItem)
    # Add current user as owner if new item.
    if ret['insert']:
        totalPaid = ret['sharedItem']['currentPrice'] if int(ret['sharedItem']['bought']) > 0 else 0
        sharedItemOwner = {
            'sharedItemId': ret['sharedItem']['_id'],
            'userId': ret['sharedItem']['currentOwnerUserId'],
            'monthlyPayment': 0,
            'totalPaid': totalPaid,
            'totalOwed': 0,
            'generation': int(ret['sharedItem']['generation']) + 1,
            'investorOnly': 0,
        }
        retOwner = _shared_item_owner.Save(sharedItemOwner)
        ret['sharedItemOwner'] = retOwner['sharedItemOwner']

    return ret

def UpdateCachedOwners(sharedItemId: str):
    sharedItem = _mongo_db_crud.GetById('sharedItem', sharedItemId)['sharedItem']
    query = {
        'sharedItemId': sharedItemId,
        'generation': sharedItem['generation'] + 1,
    }
    sharedItemOwners = _mongo_db_crud.Search('sharedItemOwner', query = query)['sharedItemOwners']
    sharedItemNew = {
        '_id': sharedItem['_id'],
        'pledgedOwners': 0,
        'fundingRequired': 0 if int(sharedItem['bought']) > 0 else float(sharedItem['currentPrice']),
    }
    for owner in sharedItemOwners:
        if not int(owner['investorOnly']):
            sharedItemNew['pledgedOwners'] += 1
        if int(sharedItem['bought']) < 1:
            sharedItemNew['fundingRequired'] -= owner['totalPaid']
    if sharedItemNew['fundingRequired'] < 0:
        sharedItemNew['fundingRequired'] = 0
    ret = _mongo_db_crud.Save('sharedItem', sharedItemNew)
    return ret
