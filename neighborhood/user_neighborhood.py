from common import mongo_db_crud as _mongo_db_crud
import mongo_db

def SetAllStatus(userId: str, status: str = ''):
    mongo_db.update_one('userNeighborhood', {'userId': userId}, {'$set': {'status': status}})

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