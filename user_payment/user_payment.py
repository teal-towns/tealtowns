from common import mongo_db_crud as _mongo_db_crud
import mongo_db
from shared_item import shared_item_payment_math as _shared_item_payment_math

def AddPayment(userId: str, amountUSD: float, forType: str, forId: str, status: str = 'complete', notes: str = '',
    removeCutFromBalance: int = 0):
    ret = _mongo_db_crud.Save('userPayment', {
        'userId': userId,
        'amountUSD': amountUSD,
        'forType': forType,
        'forId': forId,
        'status': status,
        'notes': notes,
    })
    if status == 'complete':
        UpdateBalance(userId, amountUSD, removeCutFromBalance = removeCutFromBalance)
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
    return ret

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
