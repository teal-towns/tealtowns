from common import mongo_db_crud as _mongo_db_crud
import lodash
import mongo_db
from user import user_availability as _user_availability

def Save(userInterest: dict):
    ret = _mongo_db_crud.Save('userInterest', userInterest, checkGetKey = 'username')
    retCheck =_user_availability.CheckCommonInterestsAndTimesByUser(userInterest['username'])
    ret['weeklyEventsCreated'] = retCheck['weeklyEventsCreated']
    ret['weeklyEventsInvited'] = retCheck['weeklyEventsInvited']
    ret['notifyUserIds'] = retCheck['notifyUserIds']
    return ret

def GetInterestsByNeighborhood(neighborhoodUName: str, groupByInterest: int = 1, groupedSortKey: str = ''):
    ret = { 'valid': 1, 'message': '', 'userInterests': [], 'interestsGrouped': [] }
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
