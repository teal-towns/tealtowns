from common import math_polygon as _math_polygon
from common import mongo_db_crud as _mongo_db_crud

def SearchNear(lngLat: list, maxMeters: float, title: str = '', limit: int = 250, skip: int = 0, withHosts: int = 1):
    query = {
        'location': {
            '$nearSphere': {
                '$geometry': {
                    'type': 'Point',
                    'coordinates': lngLat,
                },
                '$maxDistance': maxMeters,
            }
        },
    }
    sortKeys = "dayOfWeek,startTime"
    ret = _mongo_db_crud.Search('weeklyEvent', {'title': title}, limit = limit, skip = skip, query = query,
        sortKeys = sortKeys)
    userIds = []
    # Calculate distance
    # May also be able to use geoNear https://stackoverflow.com/questions/33864461/mongodb-print-distance-between-two-points
    for index, item in reversed(list(enumerate(ret['weeklyEvents']))):
        ret['weeklyEvents'][index]['xDistanceKm'] = round(_math_polygon.Haversine(item['location']['coordinates'],
            lngLat, units = 'kilometers'), 3)
        if withHosts:
            for userId in item['hostUserIds']:
                if userId not in userIds:
                    userIds.append(userId)

    if len(userIds) > 0 and withHosts:
        listKeyVals = { '_id': userIds }
        fields = { "firstName": 1, "lastName": 1, "email": 1, }
        users = _mongo_db_crud.Search('user', listKeyVals = listKeyVals, fields = fields, limit = limit * 10)['users']
        usersIdMap = {}
        for user in users:
            usersIdMap[user['_id']] = user
        for indexEvent, event in enumerate(ret['weeklyEvents']):
            if 'hostUsers' not in ret['weeklyEvents'][indexEvent]:
                ret['weeklyEvents'][indexEvent]['hostUsers'] = []
            for userId in event['hostUserIds']:
                user = usersIdMap[userId] if userId in usersIdMap else {}
                ret['weeklyEvents'][indexEvent]['hostUsers'].append(user)

    return ret

def GetById(weeklyEventId: str, withHosts: int = 1):
    ret = _mongo_db_crud.GetById('weeklyEvent', weeklyEventId)
    if withHosts:
        userIds = []
        for userId in ret['weeklyEvent']['hostUserIds']:
            if userId not in userIds:
                userIds.append(userId)
        listKeyVals = { '_id': userIds }
        fields = { "firstName": 1, "lastName": 1, "email": 1, }
        users = _mongo_db_crud.Search('user', listKeyVals = listKeyVals, fields = fields)['users']
        usersIdMap = {}
        for user in users:
            usersIdMap[user['_id']] = user
        ret['weeklyEvent']['hostUsers'] = []
        for userId in ret['weeklyEvent']['hostUserIds']:
            user = usersIdMap[userId] if userId in usersIdMap else {}
            ret['weeklyEvent']['hostUsers'].append(user)
    return ret
