import datetime

import date_time
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
    else:
        if 'ambassadorSignUpStepsAt' not in userInsight:
            userInsight['ambassadorSignUpStepsAt'] = {}
        if 'username' not in userInsight:
            user = mongo_db.find_one('user', { '_id': userInsight['userId'] })['item']
            userInsight['username'] = user['username']
    return _mongo_db_crud.Save('userInsight', userInsight)

def SetActionAt(userId: str, field: str, now = None):
    now = now if now is not None else date_time.now()
    ret = { "valid": 1, "message": "" }
    query = { 'userId': userId }
    mutation = { '$set': {} }
    mutation['$set'][field] = date_time.string(now)
    retOne = mongo_db.update_one('userInsight', query, mutation, validate = 0)
    if retOne['modified_count'] < 1:
        ret['valid'] = 0
    return ret

def GetAmbassadorInsights(now = None, withUsers: int = 1):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 1, 'message': '', 'ambassadorsSignUpCompleteCount': 0, 'userInsights': [],
        'currentAmbassadorsCount': 0, 'usersNotCurrent': [], }
    lastMonth = date_time.string(now - datetime.timedelta(days = 30))
    fields = { 'userId': 1, 'ambassadorSignUpStepsAt': 1, }
    # First see who has completed all of the ambassador sign up steps.
    query = { 'ambassadorSignUpStepsAt.userNeighborhoodSave': { '$gte': lastMonth },
        'ambassadorSignUpStepsAt.resources': { '$exists': 1 } }
    userInsights = mongo_db.find('userInsight', query, fields = fields)['items']
    ret['ambassadorsSignUpCompleteCount'] = len(userInsights)
    userIds = []
    for userInsight in userInsights:
        userIds.append(userInsight['userId'])
    query = { 'ambassadorSignUpStepsAt.userNeighborhoodSave': { '$gte': lastMonth }, 'userId': { '$nin': userIds } }
    ret['userInsights'] = mongo_db.find('userInsight', query, fields = fields)['items']
    if withUsers > 0:
        userObjectIds = []
        userIdMap = {}
        for index, userInsight in enumerate(ret['userInsights']):
            userObjectIds.append(mongo_db.to_object_id(userInsight['userId']))
            userIdMap[userInsight['userId']] = index
        query = { '_id': { '$in': userObjectIds } }
        fields = { 'firstName': 1, 'lastName': 1, 'username': 1, 'email': 1 }
        users = mongo_db.find('user', query, fields = fields)['items']
        for user in users:
            ret['userInsights'][userIdMap[user['_id']]]['user'] = user

    # See which ambassadors who have been active this month, are up to date
    lastWeek = date_time.string(now - datetime.timedelta(days = 7))
    # Start with users who have made an update in the past week.
    query = { 'start': { '$gte': lastWeek }, 'inviteCount': { '$gt': 0 } }
    userNeighborhoodWeeklyUpdates = mongo_db.find('userNeighborhoodWeeklyUpdate', query)['items']
    userIdsCurrent = []
    for userNeighborhoodWeeklyUpdate in userNeighborhoodWeeklyUpdates:
        if userNeighborhoodWeeklyUpdate['userId'] not in userIdsCurrent:
            userIdsCurrent.append(userNeighborhoodWeeklyUpdate['userId'])
    ret['currentAmbassadorsCount'] = len(userIdsCurrent)
    # Find the rest who have been active this month but not this week.
    query = { 'start': { '$gte': lastMonth }, 'inviteCount': { '$gt': 0 }, 'userId': { '$nin': userIdsCurrent } }
    userIds = mongo_db.findDistinct('userNeighborhoodWeeklyUpdate', 'userId', query)['values']
    userObjectIds = []
    for userId in userIds:
        userObjectIds.append(mongo_db.to_object_id(userId))
    query = { '_id': { '$in': userObjectIds } }
    fields = { 'firstName': 1, 'lastName': 1, 'username': 1, 'email': 1 }
    ret['usersNotCurrent'] = mongo_db.find('user', query, fields = fields)['items']

    return ret
