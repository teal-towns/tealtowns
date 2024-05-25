from common import mongo_db_crud as _mongo_db_crud
import mongo_db
from shared_item import shared_item_payment_math as _shared_item_payment_math
from event import weekly_event as _weekly_event
from shared_item import shared_item as _shared_item
from user_auth import user as _user

def AddPayment(userId: str, amountUSD: float, forType: str, forId: str, status: str = 'complete', notes: str = '',
    removeCutFromBalance: int = 0, amountUSDPreFee: float = 0):
    amountUSDPreFee = amountUSDPreFee if amountUSDPreFee != 0 else amountUSD
    ret = _mongo_db_crud.Save('userPayment', {
        'userId': userId,
        'amountUSD': amountUSD,
        'amountUSDPreFee': amountUSDPreFee,
        'forType': forType,
        'forId': forId,
        'status': status,
        'notes': notes,
    })
    if status == 'complete':
        UpdateBalance(userId, amountUSD, removeCutFromBalance = removeCutFromBalance)
        CheckMoveRevenueToBank(amountUSDPreFee, forType, forId)
    return ret

def UpdatePayment(userPaymentId: str, status: str, removeCutFromBalance: int = 0):
    query = {
        '_id': mongo_db.to_object_id(userPaymentId),
    }
    mutation = {
        '$set': {
            'status': status,
        }
    }
    ret = mongo_db.update_one('userPayment', query, mutation)
    if status == 'complete':
        item = mongo_db.find_one('userPayment', query)["item"]
        UpdateBalance(item['userId'], item['amountUSD'], removeCutFromBalance = removeCutFromBalance)
        CheckMoveRevenueToBank(item['amountUSDPreFee'], item['forType'], item['forId'])
    return ret

def AddPaymentSubscription(userPaymentSubscription: dict):
    ret = _mongo_db_crud.Save('userPaymentSubscription', userPaymentSubscription)
    if userPaymentSubscription['status'] == 'complete':
        # Make negative to pass in as we only take revenue on payments from a user, which are negative amounts,
        # but subscriptions are always stored as positive.
        amountUSDPreFee = -1 * userPaymentSubscription['amountUSD']
        CheckMoveRevenueToBank(amountUSDPreFee, userPaymentSubscription['forType'], userPaymentSubscription['forId'])
    return ret

def CheckMoveRevenueToBank(amountUSDPreFee: float, forType: str, forId: str):
    # Only move revenue if a payment FROM the user.
    # if amountUSDPreFee < 0:
    # TODO
    pass

def UpdateBalance(userId: str, amountUSD: float, removeCutFromBalance: int = 0):
    amountFinal = amountUSD
    if removeCutFromBalance:
        amountFinal = amountUSD + _shared_item_payment_math.GetCut(amountUSD)

    query = {
        'userId': userId,
    }
    item = mongo_db.find_one('userMoney', query)["item"]
    if item is None:
        ret = _mongo_db_crud.Save('userMoney', {
            'userId': userId,
            'balanceUSD': amountFinal,
        })
    else:
        query = {
            'userId': userId,
        }
        mutation = {
            '$inc': {
                'balanceUSD': amountFinal,
            }
        }
        ret = mongo_db.update_one('userMoney', query, mutation)
    return ret

# def GetUserMoney(userId: str):
#     ret = { 'valid': 1, 'message': '', 'userMoney': {}, 'availableUSD': 0 }
#     query = {
#         'userId': userId,
#     }
#     item = mongo_db.find_one('userMoney', query)['item']
#     if item is not None:
#         ret['userMoney'] = item
#         ret['availableUSD'] = ret['userMoney']['balanceUSD']
#     return ret

def GetUserMoneyAndPending(userId: str):
    ret = { 'valid': 1, 'message': '', 'userMoney': {}, 'userPayments': [], 'availableUSD': 0 }
    query = {
        'userId': userId,
    }
    item = mongo_db.find_one('userMoney', query)['item']
    if item is not None:
        ret['userMoney'] = item

        query = {
            'userId': userId,
            'status': 'pending',
        }
        retPayments = _mongo_db_crud.Search('userPayment', query = query)
        ret['userPayments'] = retPayments['userPayments']
        ret['availableUSD'] = ret['userMoney']['balanceUSD']
        for payment in ret['userPayments']:
            ret['availableUSD'] += payment['amountUSD']

    return ret

def GetForLink(forType: str, forId: str):
    ret = { 'valid': 1, 'message': '', 'forLink': '' }
    if forType == 'weeklyEvent':
        item = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(forId)})['item']
        if item is not None:
            ret['forLink'] = _weekly_event.GetUrl(item)
    elif forType == 'event':
        item = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(forId)})['item']
        if item is not None:
            weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(item['weeklyEventId'])})['item']
            if weeklyEvent is not None:
                ret['forLink'] = _weekly_event.GetUrl(weeklyEvent)
    elif forType == 'sharedItemOwner':
        item1 = mongo_db.find_one('sharedItemOwner', {'_id': mongo_db.to_object_id(forId)})['item']
        if item1 is not None:
            item = mongo_db.find_one('sharedItem', {'_id': mongo_db.to_object_id(item1['sharedItemId'])})['item']
            if item is not None:
                ret['forLink'] = _shared_item.GetUrl(item, sharedItemOwnerId = forId)
    elif forType == 'sharedItem':
        item = mongo_db.find_one('sharedItem', {'_id': mongo_db.to_object_id(forId)})['item']
        if item is not None:
            ret['forLink'] = _shared_item.GetUrl(item)
    elif forType == 'user':
        item = mongo_db.find_one('user', {'_id': mongo_db.to_object_id(forId)})['item']
        if item is not None:
            ret['forLink'] = _user.GetUrl(item)
    return ret

def AddForLinks(payments: list):
    for payment in payments:
        payment['forLink'] = GetForLink(payment['forType'], payment['forId'])['forLink']
    return payments
