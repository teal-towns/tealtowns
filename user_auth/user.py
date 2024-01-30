import lodash
import mongo_db

def SaveUser(user):
    ret = { 'valid': 0, 'message': '' } 
    query = {
        '_id': mongo_db.to_object_id(user['_id'])
    }
    saveVals = lodash.pick(user, ['first_name', 'last_name', 'lngLat'])
    if len(saveVals) > 0:
        mutation = {
            '$set': saveVals
        }
        result = mongo_db.update_one('user', query, mutation)
    return ret
