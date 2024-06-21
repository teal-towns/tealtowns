from common import mongo_db_crud as _mongo_db_crud
import date_time
import mongo_db
from insight import user_insight as _user_insight

def SetAllStatus(userId: str, status: str = ''):
    mongo_db.update_many('userNeighborhood', {'userId': userId}, {'$set': {'status': status}})

def Search(stringKeyVals: dict = {}, limit: int = 250, skip: int = 0, withNeighborhoods: int = 0):
    ret = _mongo_db_crud.Search('userNeighborhood', stringKeyVals = stringKeyVals, limit = limit, skip = skip)
    if withNeighborhoods:
        neighborhoodObjectIds = []
        idIndexMap = {}
        for index, userNeighborhood in enumerate(ret['userNeighborhoods']):
            neighborhoodObjectIds.append(mongo_db.to_object_id(userNeighborhood['neighborhoodId']))
            idIndexMap[userNeighborhood['neighborhoodId']] = index
        query = {'_id': {'$in': neighborhoodObjectIds}}
        neighborhoods = mongo_db.find('neighborhood', query)['items']
        for neighborhood in neighborhoods:
            ret['userNeighborhoods'][idIndexMap[neighborhood['_id']]]['neighborhood'] = neighborhood

    return ret

def Save(userNeighborhood: dict):
    if userNeighborhood['status'] == 'default':
        # First remove any existing defaults.
        SetAllStatus(userNeighborhood['userId'], '')
    # Check if already exists, otherwise will get duplicate error.
    query = {
        'userId': userNeighborhood['userId'],
        'neighborhoodId': userNeighborhood['neighborhoodId'],
    }
    item = mongo_db.find_one('userNeighborhood', query)['item']
    if item is not None and '_id' in item:
        userNeighborhood['_id'] = item['_id']
    ret = _mongo_db_crud.Save('userNeighborhood', userNeighborhood)
    _user_insight.Save({ 'userId': userNeighborhood['userId'], 'firstNeighborhoodJoinAt': date_time.now_string() })
    return ret