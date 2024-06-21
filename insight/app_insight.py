import datetime

import date_time
import mongo_db

def GetAppInsights(now = None, limit: int = 1000000):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 1, 'message': '', 'uniqueEventViews': 0, 'eventSignUps': 0,
        'userSignUps': 0, 'uniqueSignUpViews': 0, 'totalUsers': 0, 'activeUsers': 0,
        'hoursToFirstAction': { 'eventSignUp': -1, 'neighborhoodJoin': -1,}, }
    lastMonth = date_time.string(now - datetime.timedelta(days = 30))
    nowString = date_time.string(now)

    # Events
    fields = { '_id': 1 }
    events = mongo_db.find('event', { 'start': { '$gte': lastMonth } }, fields = fields)['items']
    eventIds = []
    for event in events:
        eventIds.append(event['_id'])

    query = { 'eventId': { '$in': eventIds }, }
    eventInsights = mongo_db.find('eventInsight', query, limit = limit)['items']
    for eventInsight in eventInsights:
        ret['uniqueEventViews'] += len(eventInsight['uniqueViewsAt'])

    query = { 'eventId': { '$in': eventIds }, }
    userEvents = mongo_db.find('userEvent', query, fields = fields, limit = limit)['items']
    ret['eventSignUps'] = len(userEvents)

    # Sign ups
    query = { 'createdAt': { '$gte': lastMonth } }
    fields = { '_id': 1, 'createdAt': 1, }
    users = mongo_db.find('user', query, fields = fields, limit = limit)['items']
    ret['userSignUps'] = len(users)

    query = { 'end': { '$lte': nowString } }
    appInsights = mongo_db.find('appInsight', query)['items']
    if len(appInsights) == 0:
        query = { 'start': { '$lte': nowString } }
        appInsights = mongo_db.find('appInsight', query)['items']
    for appInsight in appInsights:
        ret['uniqueSignUpViews'] += len(appInsight['signUpUniqueViewsAt'])

    # Active users
    query = { 'lastActiveAt': { '$gte': lastMonth } }
    userInsights = mongo_db.find('userInsight', query, limit = limit)['items']
    ret['activeUsers'] = len(userInsights)
    ret['totalUsers'] = mongo_db.Count('user')['count']

    # Hours to first action
    userIds = []
    userIdMap = {}
    for user in users:
        userIds.append(user['_id'])
        userIdMap[user['_id']] = user
    query = { 'userId': { '$in': userIds } }
    userInsights = mongo_db.find('userInsight', query, limit = limit)['items']
    eventSignUps = { 'hoursSum': 0, 'usersCount': 0, }
    neighborhoodJoins = { 'hoursSum': 0, 'usersCount': 0, }
    for userInsight in userInsights:
        createdAt = date_time.from_string(userIdMap[userInsight['userId']]['createdAt'])
        if 'firstEventSignUpAt' in userInsight:
            eventSignUps['hoursSum'] += date_time.diff(createdAt, date_time.from_string(userInsight['firstEventSignUpAt']), 'hours')
            eventSignUps['usersCount'] += 1
        if 'firstNeighborhoodJoinAt' in userInsight:
            neighborhoodJoins['hoursSum'] += date_time.diff(createdAt, date_time.from_string(userInsight['firstNeighborhoodJoinAt']), 'hours')
            neighborhoodJoins['usersCount'] += 1
    ret['hoursToFirstAction']['eventSignUp'] = eventSignUps['hoursSum'] / eventSignUps['usersCount'] \
        if eventSignUps['usersCount'] > 0 else -1
    ret['hoursToFirstAction']['neighborhoodJoin'] = neighborhoodJoins['hoursSum'] / neighborhoodJoins['usersCount'] \
        if neighborhoodJoins['usersCount'] > 0 else -1

    return ret

def AddView(fieldKey: str, userOrIP: str = '', now = None,):
    if len(userOrIP) < 0:
        # '.' is a reserved character for field names
        userOrIP = 'ip_0-0-0-0'
    now = now if now is not None else date_time.now()
    ret = { "valid": 1, "message": "", "appInsight": {}, }
    thisMonth = date_time.create(now.year, now.month, 1, 0, 0)
    # If 1st of the month, compute for last month.
    if now.day == 1:
        thisMonth = date_time.previousMonth(thisMonth)
    start = date_time.string(thisMonth)
    nextMonth = date_time.nextMonth(thisMonth)
    end = date_time.string(nextMonth)

    nowString = date_time.string(now)
    query = { 'start': start, 'end': end, }
    item = mongo_db.find_one('appInsight', query)['item']
    if item is None:
        uniqueViewsAt = {}
        uniqueViewsAt[userOrIP] = [ nowString ]
        item = { 'start': start, 'end': end, }
        item[fieldKey] = uniqueViewsAt
        mongo_db.insert_one('appInsight', item)
    elif userOrIP not in item[fieldKey]:
        key = fieldKey + '.' + userOrIP
        mutation = { '$set': {} }
        mutation['$set'][key] = [ nowString ]
        mongo_db.update_one('appInsight', query, mutation, validate = 0)
    else:
        key = fieldKey + '.' + userOrIP
        mutation = { "$push": {} }
        mutation['$push'][key] = nowString
        mongo_db.update_one('appInsight', query, mutation, validate = 0)
    return ret
