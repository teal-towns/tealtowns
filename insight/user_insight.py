from common import mongo_db_crud as _mongo_db_crud
# import lodash
import mongo_db

def Save(userInsight, skipIfExistsKeys: list = ['firstEventSignUpAt', 'firstNeighborhoodJoinAt']):
    # userInsight = lodash.extend_object({
    #     'lastActiveAt': '',
    #     'firstEventSignUpAt': '',
    #     'firstNeighborhoodJoinAt': ''
    # }, userInsight)
    item = mongo_db.find_one('userInsight', { 'userId': userInsight['userId'] })['item']
    if item is not None:
        userInsight['_id'] = item['_id']
        for key in skipIfExistsKeys:
            if key in item and key in userInsight:
                del userInsight[key]
    return _mongo_db_crud.Save('userInsight', userInsight)
