from common import math_polygon as _math_polygon
from common import mongo_db_crud as _mongo_db_crud
# import lodash

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

    if len(withOwnerUserId) > 0:
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
    if 'pledgedOwners' not in sharedItem:
        sharedItem['pledgedOwners'] = 0
    if 'fundingRequired' not in sharedItem:
        sharedItem['fundingRequired'] = sharedItem['currentPrice']
    if 'currency' not in sharedItem:
        sharedItem['currency'] = 'USD'
    return _mongo_db_crud.Save('sharedItem', sharedItem)

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
        'fundingRequired': sharedItem['currentPrice'],
    }
    for owner in sharedItemOwners:
        if not owner['investorOnly']:
            sharedItemNew['pledgedOwners'] += 1
        sharedItemNew['fundingRequired'] -= owner['totalPaid']
    ret = _mongo_db_crud.Save('sharedItem', sharedItemNew)
    return ret
