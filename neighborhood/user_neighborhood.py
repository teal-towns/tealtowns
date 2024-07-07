from common import mongo_db_crud as _mongo_db_crud
import date_time
import mongo_db
from insight import user_insight as _user_insight
from user_auth import user_auth as _user_auth

def SetAllStatus(userId: str, status: str = ''):
    mongo_db.update_many('userNeighborhood', {'userId': userId}, {'$set': {'status': status}})

def Search(stringKeyVals: dict = {}, limit: int = 250, skip: int = 0, withNeighborhoods: int = 0,
    withUsers: int = 0):
    ret = _mongo_db_crud.Search('userNeighborhood', stringKeyVals = stringKeyVals, limit = limit, skip = skip)
    if withNeighborhoods or withUsers:
        neighborhoodUNames = []
        uNameIndexMap = {}
        userObjectIds = []
        userIdIndexMap = {}
        for index, userNeighborhood in enumerate(ret['userNeighborhoods']):
            if withNeighborhoods:
                neighborhoodUNames.append(mongo_db.to_object_id(userNeighborhood['neighborhoodUName']))
                uNameIndexMap[userNeighborhood['neighborhoodUName']] = index
            if withUsers:
                userObjectIds.append(mongo_db.to_object_id(userNeighborhood['userId']))
                userIdIndexMap[userNeighborhood['userId']] = index
        if withNeighborhoods:
            query = {'uName': {'$in': neighborhoodUNames}}
            neighborhoods = mongo_db.find('neighborhood', query)['items']
            for neighborhood in neighborhoods:
                ret['userNeighborhoods'][uNameIndexMap[neighborhood['uName']]]['neighborhood'] = neighborhood
        if withUsers:
            query = {'_id': {'$in': userObjectIds}}
            fields = _user_auth.getUserFields()
            users = mongo_db.find('user', query, fields = fields)['items']
            for user in users:
                ret['userNeighborhoods'][userIdIndexMap[user['_id']]]['user'] = user

    return ret

def Save(userNeighborhood: dict):
    if userNeighborhood['status'] == 'default':
        # First remove any existing defaults.
        SetAllStatus(userNeighborhood['userId'], '')
    # Check if already exists, otherwise will get duplicate error.
    query = {
        'userId': userNeighborhood['userId'],
        'neighborhoodUName': userNeighborhood['neighborhoodUName'],
    }
    item = mongo_db.find_one('userNeighborhood', query)['item']
    if item is not None and '_id' in item:
        userNeighborhood['_id'] = item['_id']
    elif 'roles' not in userNeighborhood:
        userNeighborhood['roles'] = []
    ret = _mongo_db_crud.Save('userNeighborhood', userNeighborhood)
    _user_insight.Save({ 'userId': userNeighborhood['userId'], 'firstNeighborhoodJoinAt': date_time.now_string() })
    return ret