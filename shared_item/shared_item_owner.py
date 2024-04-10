# from pydantic import BaseModel

from common import mongo_db_crud as _mongo_db_crud
import mongo_db
from shared_item import shared_item as _shared_item
from shared_item import shared_item_payment as _shared_item_payment
from shared_item import shared_item_payment_math as _shared_item_payment_math
from user_payment import user_payment as _user_payment

# class SharedItemOwnerClass(BaseModel):
#     _id: str = ''
#     createdAt: str = ''
#     updatedAt: str = ''
#     sharedItemId: str = ''
#     userId: str = ''
#     generation: int = 0
#     monthlyPayment: float = 0
#     totalPaid: float = 0
#     totalOwed: float = 0
#     investorOnly: int = 0
#     status: str = ''
#     stripeMonthlyPriceId: str = ''

def Get(id: str = '', sharedItemId: str = '', userId: str = '', generation: int = 1, withSharedItem: int = 0,
    checkByPayment: int = 1, checkUpdatePayments: int = 0):
    ret = { 'valid': 1, 'message': '', 'sharedItemOwner': {}, 'sharedItem': {} }
    if len(id) > 0:
        ret['sharedItemOwner'] = _mongo_db_crud.GetById('sharedItemOwner', id)['sharedItemOwner']
    else:
        ret['sharedItemOwner'] = _mongo_db_crud.Get('sharedItemOwner',
            stringKeyVals = {'sharedItemId': sharedItemId, 'userId': userId, 'generation': generation})['sharedItemOwner']
    # Check for down payment. Should not have to check for monthly payment as that should only happen AFTER down payment.
    if '_id' not in ret['sharedItemOwner'] and checkByPayment and len(sharedItemId) > 0:
        query = { 'userId': userId, 'forType': 'sharedItem', 'forId': sharedItemId }
        userPayment = mongo_db.find_one('userPayment', query)['item']
        ret['sharedItem'] = _mongo_db_crud.GetById('sharedItem', sharedItemId)['sharedItem']
        if userPayment is not None:
            payInfo = _shared_item_payment_math.GetPayments(ret['sharedItem']['currentPrice'],
                ret['sharedItem']['monthsToPayBack'], ret['sharedItem']['minOwners'],
                ret['sharedItem']['maintenancePerYear'])
            totalPaid = userPayment['amountUSD']
            totalOwed = payInfo['totalToPayBack']
            status = 'pendingMonthlyPayment' if totalPaid < totalOwed else 'paid'
            sharedItemOwner = {
                'userId': userId,
                'sharedItemId': sharedItemId,
                'generation': ret['sharedItem']['generation'] + 1,
                'monthlyPayment': payInfo['monthlyPayment'],
                'totalPaid': totalPaid,
                'totalOwed': totalOwed,
                'totalPaidBack': 0,
                'investorOnly': 0,
                'status': status,
            }
            ret = Save(sharedItemOwner, skipPayment = 1)
    elif '_id' in ret['sharedItemOwner'] and checkUpdatePayments:
        retUpdate = _shared_item_payment.CheckUpdatePayments(ret['sharedItemOwner']['_id'])
        ret['sharedItemOwner'] = retUpdate['sharedItemOwner']

    sharedItemId = ret['sharedItemOwner']['sharedItemId'] if ('sharedItemId' in ret['sharedItemOwner'] and \
        len(ret['sharedItemOwner']['sharedItemId']) > 0) else sharedItemId
    if withSharedItem and len(sharedItemId) > 0:
        ret['sharedItem'] = _mongo_db_crud.GetById('sharedItem', sharedItemId)['sharedItem']

    return ret

def Save(sharedItemOwner: dict, skipPayment: int = 0, now = None):
    if '_id' not in sharedItemOwner:
        if 'totalPaidBack' not in sharedItemOwner:
            sharedItemOwner['totalPaidBack'] = 0
    # sharedItemOwner = SharedItemOwnerClass(**sharedItemOwner).dict()
    ret = _mongo_db_crud.Save('sharedItemOwner', sharedItemOwner)

    # If first time, create pending payment.
    if not skipPayment and ret['insert'] and sharedItemOwner['totalPaid'] > 0 and not sharedItemOwner['investorOnly']:
        _user_payment.AddPayment(sharedItemOwner['userId'], -1 * sharedItemOwner['totalPaid'], 'sharedItemOwner',
            ret['sharedItemOwner']['_id'], 'pending', notes = 'Down payment')

    _shared_item.UpdateCachedOwners(sharedItemOwner['sharedItemId'], now = now)
    return ret

def GetNextGenerationOwners(sharedItem, investorOnly: int = -1):
    query = {
        'sharedItemId': sharedItem['_id'],
        'generation': sharedItem['generation'] + 1,
    }
    if investorOnly >= 0:
        query['investorOnly'] = investorOnly
    return _mongo_db_crud.Search('sharedItemOwner', query = query)
