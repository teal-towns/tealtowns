import datetime

from common import mongo_db_crud as _mongo_db_crud
import date_time
import mongo_db

def Save(userNeighborhoodWeeklyUpdate: dict, now = None, weekdayStart: int = 0):
    now = now if now is not None else date_time.now()
    userNeighborhoodWeeklyUpdate = _mongo_db_crud.CleanId(userNeighborhoodWeeklyUpdate)
    if '_id' not in userNeighborhoodWeeklyUpdate:
        thisWeek = date_time.create(now.year, now.month, now.day, 0, 0)
        if thisWeek.weekday() != weekdayStart:
            days = thisWeek.weekday() - weekdayStart
            thisWeek = thisWeek - datetime.timedelta(days = days)
        userNeighborhoodWeeklyUpdate['start'] = date_time.string(thisWeek)
        userNeighborhoodWeeklyUpdate['end'] = date_time.string(thisWeek + datetime.timedelta(days = 7))
        # Check if already exists, otherwise will get duplicate error.
        query = {
            'userId': userNeighborhoodWeeklyUpdate['userId'],
            'neighborhoodUName': userNeighborhoodWeeklyUpdate['neighborhoodUName'],
            'start': userNeighborhoodWeeklyUpdate['start'],
        }
        item = mongo_db.find_one('userNeighborhoodWeeklyUpdate', query)['item']
        if item is not None and '_id' in item:
            userNeighborhoodWeeklyUpdate['_id'] = item['_id']

    ret = _mongo_db_crud.Save('userNeighborhoodWeeklyUpdate', userNeighborhoodWeeklyUpdate)
    return ret

def Search(stringKeyVals, minKeyVals: dict = {}, maxKeyVals: dict = {}, limit: int = 25, skip: int = 0,
    sortKeys: str = '-start', withEventsAttendedCount: int = 0):
    ret = _mongo_db_crud.Search('userNeighborhoodWeeklyUpdate', stringKeyVals = stringKeyVals,
        minKeyVals = minKeyVals, maxKeyVals = maxKeyVals, limit = limit, skip = skip,
        sortKeys = sortKeys)
    if withEventsAttendedCount == 1 and len(ret['userNeighborhoodWeeklyUpdates']) > 0:
        userId = ret['userNeighborhoodWeeklyUpdates'][0]['userId']
        startMin = ''
        startMax = ''
        if 'start' in minKeyVals:
            startMin = minKeyVals['start']
        if 'start' in maxKeyVals:
            startMax = maxKeyVals['startMax']
        if startMin == '' or startMax == '':
            for userNeighborhoodWeeklyUpdate in ret['userNeighborhoodWeeklyUpdates']:
                if startMin == '' or userNeighborhoodWeeklyUpdate['start'] < startMin:
                    startMin = userNeighborhoodWeeklyUpdate['start']
                if startMax == '' or userNeighborhoodWeeklyUpdate['start'] > startMax:
                    startMax = userNeighborhoodWeeklyUpdate['start']
            query = { 'attended': 'yes', 'forType': 'event', 'userId': userId,
                'createdAt': { '$gte': startMin, '$lte': startMax } }
            userFeedbacks = mongo_db.find('userFeedback', query)['items']
            for userFeedback in userFeedbacks:
                for index, userNeighborhoodWeeklyUpdate in enumerate(ret['userNeighborhoodWeeklyUpdates']):
                    if userFeedback['createdAt'] >= userNeighborhoodWeeklyUpdate['start'] and \
                        userFeedback['createdAt'] < userNeighborhoodWeeklyUpdate['end']:
                        if 'eventsAttendedCount' not in ret['userNeighborhoodWeeklyUpdates'][index]:
                            ret['userNeighborhoodWeeklyUpdates'][index]['eventsAttendedCount'] = 0
                        ret['userNeighborhoodWeeklyUpdates'][index]['eventsAttendedCount'] += 1
                        break
        
    return ret
