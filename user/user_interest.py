import threading

from common import mongo_db_crud as _mongo_db_crud
import lodash
import mongo_db
from user import user_availability as _user_availability

_testMode = 0
def SetTestMode(testMode: int):
    global _testMode
    _testMode = testMode

def Save(userInterest: dict, useThread: int = 1):
    userInterest = _mongo_db_crud.CleanId(userInterest)
    ret = _mongo_db_crud.Save('userInterest', userInterest, checkGetKey = 'username')
    if useThread and not _testMode:
        thread = threading.Thread(target=_user_availability.CheckCommonInterestsAndTimesByUser, args=(userInterest['username'],))
        thread.start()
        return ret
    retCheck = _user_availability.CheckCommonInterestsAndTimesByUser(userInterest['username'])
    ret['weeklyEventsCreated'] = retCheck['weeklyEventsCreated']
    ret['weeklyEventsInvited'] = retCheck['weeklyEventsInvited']
    ret['notifyUserIds'] = retCheck['notifyUserIds']
    return ret

def GetInterestsByNeighborhood(neighborhoodUName: str, groupByInterest: int = 1, groupedSortKey: str = '',
    type: str = ''):
    ret = { 'valid': 1, 'message': '', 'userInterests': [], 'interestsGrouped': [], 'type': type, }
    fields = { 'username': 1, }
    query = { 'neighborhoodUName': neighborhoodUName }
    items = mongo_db.find('userNeighborhood', query, fields = fields)['items']
    usernames = [ item['username'] for item in items ]
    query = { 'username': { '$in': usernames } }
    ret['userInterests'] = mongo_db.find('userInterest', query)['items']
    if groupByInterest == 1:
        interestIndexMap = {}
        ret['interestsGrouped'] = []
        for item in ret['userInterests']:
            for interest in item['interests']:
                if len(type) < 1 or (type == 'event' and 'event_' in interest) or (type == 'common' and '_' not in interest):
                    if interest not in interestIndexMap:
                        ret['interestsGrouped'].append({
                            'interest': interest,
                            'count': 0,
                            'usernames': []
                        })
                        interestIndexMap[interest] = len(ret['interestsGrouped']) - 1
                    index1 = interestIndexMap[interest]
                    ret['interestsGrouped'][index1]['count'] += 1
                    ret['interestsGrouped'][index1]['usernames'].append(item['username'])
        if groupedSortKey in ['count', 'username', 'interest', '-username', '-interest', '-count']:
            ret['interestsGrouped'] = lodash.sort2D(ret['interestsGrouped'], groupedSortKey)
    return ret

def GetEventInterests():
    default = {
        'price': 0,
    }
    eventInterests = {
        'event_theWeek': {
            'title': 'The Week',
            'description': 'The Week is a 3 part documentary and discussion series. A powerful group experience that sparks courageous conversations about the climate crisis, and what we can do about it. Watch the trailer at https://theweek.ooo then join us to watch 1 episode each week.',
            'imageUrls': ['/assets/assets/images/events/the-week.jpg'],
        },
        'event_onePercentGreenerWalk': {
            'title': 'One Percent Greener Walk',
            'description': 'Join neighbors to get outside, be active, and chat about how you can green your neighborhood together.',
            'imageUrls': ['/assets/assets/images/events/people-walking-in-park.jpg'],
        },
        'event_sharedMeal': {
            'title': 'Shared Meal',
            'description': 'Join your neighbors to eat a meal together.',
            'imageUrls': ['/assets/assets/images/shared-meal.jpg'],
        },
        'event_kidPlayDate': {
            'title': 'Kid Play Date',
            'description': 'Meet local parents to let kids of all ages play together. Join a hand-me-down tree, form babysitting collectives, share baby food recipes, form Dad and Mom groups, or just take a break and meet other parents while helping your child socialize.',
            'imageUrls': ['/assets/assets/images/events/children-playing.jpg'],
        },
    }
    for key in eventInterests:
        eventInterests[key] = lodash.extend_object(default, eventInterests[key])
    return { 'valid': 1, 'message': '', 'eventInterests': eventInterests }
