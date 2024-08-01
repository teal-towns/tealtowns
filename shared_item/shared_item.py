# from pydantic import BaseModel

import date_time
from common import math_polygon as _math_polygon
from common import mongo_db_crud as _mongo_db_crud
import lodash
import mongo_db
from shared_item import shared_item_owner as _shared_item_owner
from shared_item import shared_item_payment as _shared_item_payment
from shared_item import shared_item_payment_math as _shared_item_payment_math
import ml_config

_config = ml_config.get_config()

# TODO - type check all fields; add defaults for insert but NOT for update.
# class SharedItemClass(BaseModel):
#     _id: str = ''
#     createdAt: str = ''
#     updatedAt: str = ''
#     title: str = ''
#     description: str = ''
#     imageUrls: list = []
#     currentOwnerUserId: str = ''
#     currentPurchaserUserId: str = ''
#     tags: list = []
#     location: dict = {}
#     bought: int = 0
#     originalPrice: float = 0
#     currentPrice: float = 0
#     currency: str = ''
#     generation: int = 0
#     currentGenerationStart: str = ''
#     monthsToPayBack: int = 0
#     maintenancePerYear: float = 0
#     maintenanceAvailable: float = 0
#     minOwners: int = 0
#     maxOwners: int = 0
#     maxMeters: float = 0
#     status: str = ''
#     pledgedOwners: int = 0
#     fundingRequired: float = 0

def SearchNear(lngLat: list, maxMeters: float, title: str = '', tags: list = [], fundingRequired_min: float = -1,
    fundingRequired_max: float = -1, limit: int = 25, skip: int = 0, withOwnerUserId: str = '',
    myType: str = '', status: str = 'available', currentOwnerUserId: str = ''):
    query = {}
    listKeyVals = {}
    useDistance = 0
    if len(myType) > 0 and len(withOwnerUserId) > 0:
        if myType == 'purchaser':
            query = {
                'currentPurchaserUserId': withOwnerUserId,
            }
        elif myType == 'owner':
            queryTemp = {
                'userId': withOwnerUserId,
            }
            retTemp = _mongo_db_crud.Search('sharedItemOwner', query = queryTemp)
            sharedItemIds = []
            for item in retTemp['sharedItemOwners']:
                sharedItemIds.append(item['sharedItemId'])
            listKeyVals['_id'] = sharedItemIds

    else:
        useDistance = 1
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
        }
    minKeyVals = {}
    if fundingRequired_min > 0:
        minKeyVals['fundingRequired'] = fundingRequired_min
    maxKeyVals = {}
    if fundingRequired_max > 0:
        maxKeyVals['fundingRequired'] = fundingRequired_max
    listKeyVals['tags'] = tags
    stringKeyVals = { 'title': title, }
    equalsKeyVals = {}
    if len(status) > 0:
        equalsKeyVals['status'] = status
    if len(currentOwnerUserId) > 0:
        equalsKeyVals['currentOwnerUserId'] = currentOwnerUserId
    ret = _mongo_db_crud.Search('sharedItem', stringKeyVals = stringKeyVals, listKeyVals = listKeyVals,
        equalsKeyVals = equalsKeyVals,
        minKeyVals = minKeyVals, maxKeyVals = maxKeyVals, limit = limit, skip = skip, query = query)
    sharedItemIds = []
    sharedItemIndexMap = {}
    # Calculate distance
    # May also be able to use geoNear https://stackoverflow.com/questions/33864461/mongodb-print-distance-between-two-points
    for index, item in reversed(list(enumerate(ret['sharedItems']))):
        addIt = 1
        if useDistance:
            ret['sharedItems'][index]['xDistanceKm'] = _math_polygon.Haversine(item['location']['coordinates'],
                lngLat, units = 'kilometers')
            # Remove if too far away (based on sharedItem.maxMeters)
            if ret['sharedItems'][index]['xDistanceKm'] * 1000 > float(ret['sharedItems'][index]['maxMeters']):
                del ret['sharedItems'][index]
                addIt = 0
        if addIt:
            sharedItemIds.append(item['_id'])
            sharedItemIndexMap[item['_id']] = index

    if len(sharedItemIds) > 0 and len(withOwnerUserId) > 0:
        listKeyVals = {'sharedItemId': sharedItemIds }
        stringKeyVals = {'userId': withOwnerUserId}
        sharedItemOwners = _mongo_db_crud.Search('sharedItemOwner', listKeyVals = listKeyVals,
            stringKeyVals = stringKeyVals)['sharedItemOwners']
        for owner in sharedItemOwners:
            index = sharedItemIndexMap[owner['sharedItemId']]
            # Check generation (ensure 1 above current)
            if owner['generation'] == ret['sharedItems'][index]['generation'] + 1:
                ret['sharedItems'][index]['sharedItemOwner_current'] = owner

    return ret

def GetById(id: str, uName: str = '', withOwnerUserId: str = ''):
    ret = _mongo_db_crud.GetById('sharedItem', id, uName = uName)
    if ret['valid'] and len(withOwnerUserId) > 0:
        query = { 'userId': withOwnerUserId, 'sharedItemId': ret['sharedItem']['_id'] }
        sharedItemOwner = mongo_db.find_one('sharedItemOwner', query)['item']
        # Check generation (ensure 1 above current)
        if sharedItemOwner is not None and sharedItemOwner['generation'] == ret['sharedItem']['generation'] + 1:
            ret['sharedItem']['sharedItemOwner_current'] = sharedItemOwner
    return ret

def Save(sharedItem: dict, now = None):
    ret = { 'valid': 1, 'message': '', 'sharedItem': {}, 'sharedItemOwner': {} }
    sharedItem = _mongo_db_crud.CleanId(sharedItem)
    if '_id' not in sharedItem:
        sharedItem['uName'] = lodash.CreateUName(sharedItem['title'])
    if 'fundingRequired' not in sharedItem and 'currentPrice' in sharedItem:
        sharedItem['fundingRequired'] = sharedItem['currentPrice']
    insertDefaults = {
        'pledgedOwners': 0,
        'currency': 'USD',
        'status': 'available',
        'currentGenerationStart': date_time.now_string(),
    }
    # sharedItem = SharedItemClass(**sharedItem).dict()
    retCheck = mongo_db.Validate('sharedItem', sharedItem, insertDefaults = insertDefaults)
    if not retCheck['valid']:
        return retCheck
    sharedItem = retCheck['item']

    sharedItem['bought'] = int(sharedItem['bought'])
    ret = _mongo_db_crud.Save('sharedItem', sharedItem)
    # Add current user as owner if new item.
    if ret['insert']:
        # If not bought, set payments to minimum owners amount.
        totalPaid = ret['sharedItem']['currentPrice']
        monthlyPayment = 0
        totalOwed = 0
        if not ret['sharedItem']['bought']:
            paymentInfo = _shared_item_payment_math.GetPayments(sharedItem['currentPrice'], sharedItem['monthsToPayBack'],
                sharedItem['minOwners'], sharedItem['maintenancePerYear'])
            totalPaid = paymentInfo['downPerPerson']
            monthlyPayment = paymentInfo['monthlyPayment']
            totalOwed = paymentInfo['totalPerPerson']
        sharedItemOwner = {
            'sharedItemId': ret['sharedItem']['_id'],
            'userId': ret['sharedItem']['currentOwnerUserId'],
            'monthlyPayment': monthlyPayment,
            'totalPaid': totalPaid,
            'totalOwed': totalOwed,
            'totalPaidBack': 0,
            'generation': int(ret['sharedItem']['generation']) + 1,
            'investorOnly': 0,
            'status': '',
        }
        skipPayment = 1 if sharedItem['bought'] else 0
        sharedItemOwner['status'] = 'paid' if sharedItem['bought'] else 'pendingMonthlyPayment'
        retOwner = _shared_item_owner.Save(sharedItemOwner, skipPayment = skipPayment)
        ret['sharedItemOwner'] = retOwner['sharedItemOwner']

    retUpdate = UpdateCachedOwners(ret['sharedItem']['_id'], now = now)
    ret['sharedItem'] = retUpdate['sharedItem']

    return ret

def UpdateCachedOwners(sharedItemId: str, now = None):
    ret = { 'valid': 1, 'message': '', 'sharedItem': {}, }
    sharedItem = _mongo_db_crud.GetById('sharedItem', sharedItemId)['sharedItem']
    ret['sharedItem'] = sharedItem
    if sharedItem['status'] == 'available':
        retOwners = _shared_item_owner.GetNextGenerationOwners(sharedItem)
        sharedItemOwners = retOwners['sharedItemOwners']
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
        retSave = _mongo_db_crud.Save('sharedItem', sharedItemNew)
        ret['sharedItem']['pledgedOwners'] = retSave['sharedItem']['pledgedOwners']
        ret['sharedItem']['fundingRequired'] = retSave['sharedItem']['fundingRequired']

        # Check if can purchase.
        sharedItem['pledgedOwners'] = sharedItemNew['pledgedOwners']
        sharedItem['fundingRequired'] = sharedItemNew['fundingRequired']
        retPurchase = _shared_item_payment.CanStartPurchase(sharedItem)
        if retPurchase['canStartPurchase']:
            _shared_item_payment.StartPurchase(sharedItem, now = now)

    return ret

def GetUrl(sharedItem: dict, sharedItemOwnerId: str = ''):
    # return _config['web_server']['urls']['base'] + '/si/' + str(sharedItem['uName'])
    url = _config['web_server']['urls']['base'] + '/shared-item-owner-save?sharedItemId=' + sharedItem['_id']
    if len(sharedItemOwnerId) > 0:
        url += '&id=' + sharedItemOwnerId
    return url
