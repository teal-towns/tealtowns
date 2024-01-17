# from pydantic import BaseModel

from common import mongo_db_crud as _mongo_db_crud
from shared_item import shared_item as _shared_item
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

def Get(id: str = '', sharedItemId: str = '', userId: str = '', generation: int = 1, withSharedItem: int = 0):
    ret = { 'valid': 1, 'message': '', 'sharedItemOwner': {}, 'sharedItem': {} }
    if len(id) > 0:
        ret['sharedItemOwner'] = _mongo_db_crud.GetById('sharedItemOwner', id)['sharedItemOwner']
    else:
        ret['sharedItemOwner'] = _mongo_db_crud.Get('sharedItemOwner',
            stringKeyVals = {'sharedItemId': sharedItemId, 'userId': userId, 'generation': generation})['sharedItemOwner']
    # if '_id' not in ret['sharedItemOwner']:
    #     ret['valid'] = 0
    #     ret['message'] = 'No item found for id ' + id + ' or sharedItemId ' + sharedItemId + ' and userId ' + userId
    #     return ret

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
