from common import mongo_db_crud as _mongo_db_crud
from shared_item import shared_item as _shared_item

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

def Save(sharedItemOwner):
    ret = _mongo_db_crud.Save('sharedItemOwner', sharedItemOwner)
    _shared_item.UpdateCachedOwners(sharedItemOwner['sharedItemId'])
    return ret
