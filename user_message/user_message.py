from common import mongo_db_crud as _mongo_db_crud
from event import weekly_event as _weekly_event
import mongo_db
from notifications_all import sms_twilio as _sms_twilio

def Search(stringKeyVals: dict, limit: int, skip: int, sortKeys: str = '-updatedAt',
    withUsers: int = 0, withForIds: int = 0):
    ret = _mongo_db_crud.Search('userMessage', stringKeyVals = stringKeyVals, limit = limit,
        skip = skip)
    if withUsers or withForIds:
        userIds = []
        userIndicesMap = {}
        # Grouped by forType
        forInfos = {}
        forInfosIndicesMap = {}
        for index, item in enumerate(ret['userMessages']):
            if withUsers:
                if item['userId'] not in userIds:
                    userIds.append(item['userId'])
                if item['userId'] not in userIndicesMap:
                    userIndicesMap[item['userId']] = []
                userIndicesMap[item['userId']].append(index)
            if withForIds:
                if item['forType'] not in forInfos:
                    forInfos[item['forType']] = []
                if item['forId'] not in forInfos[item['forType']]:
                    forInfos[item['forType']].append(item['forId'])
                if item['forType'] not in forInfosIndicesMap:
                    forInfosIndicesMap[item['forType']] = {}
                if item['forId'] not in forInfosIndicesMap[item['forType']]:
                    forInfosIndicesMap[item['forType']][item['forId']] = []
                forInfosIndicesMap[item['forType']][item['forId']].append(index)
        if withUsers:
            fields = {'firstName': 1, 'lastName': 1, 'username': 1,}
            query = { '_id': { '$in': userIds } }
            users = mongo_db.find('user', query, fields = fields)['items']
            for user in users:
                for index in userIndicesMap[user['_id']]:
                    ret['userMessages'][index]['user'] = user
        if withForIds:
            for forType in forInfos:
                query = { '_id': { '$in': forInfos[forType] } }
                items = mongo_db.find(forType, query)['items']
                for item in items:
                    for index in forInfosIndicesMap[forType][item['_id']]:
                        ret['userMessages'][index]['for'] = item
    return ret

def GetById(id: str, withUser: int = 0, withForId: int = 0, withLikeUsers: int = 0,
    withSubMessages: int = 0):
    ret = _mongo_db_crud.GetById('userMessage', id)
    if '_id' in ret['userMessage']:
        if withUser:
            fields = {'firstName': 1, 'lastName': 1, 'username': 1,}
            ret['userMessage']['user'] = _mongo_db_crud.GetById('user', ret['userMessage']['userId'],
                fields = fields)
        if withForId:
            ret['userMessage']['for'] = _mongo_db_crud.GetById(ret['userMessage']['forType'], ret['userMessage']['forId'])
        if withLikeUsers:
            fields = {'firstName': 1, 'lastName': 1, 'username': 1,}
            ret['userMessage']['likeUsers'] = _mongo_db_crud.GetByIds('user',
                ret['userMessage']['likeUserIds'], fields = fields)
        if withSubMessages:
            fields = { 'updatedAt': 1, 'userId': 1, 'message': 1, 'likeUserIds': 1, }
            ret['userMessage']['subMessages'] = _mongo_db_crud.GetByIds('userMessage',
                ret['userMessage']['subMessageIds'], fields = fields)

    return ret

def Save(userMessage: dict):
    ret = _mongo_db_crud.Save('userMessage', userMessage)
    # Notify
    if ret['valid'] == 1:
        if userMessage['type'] == 'neighborhood':
            query = { 'neighborhoodId': userMessage['typeId'], 'status': 'default', }
            fields = { 'userId': 1, }
            userNeighborhoods = mongo_db.find('userNeighborhood', query, fields = fields)['items']
            userIds = []
            for userNeighborhood in userNeighborhoods:
                userIds.append(userNeighborhood['userId'])
            body = userMessage['message']
            if userMessage['forType'] == 'weeklyEvent':
                query = {'_id': mongo_db.to_object_id(userMessage['forId'])}
                fields = { 'uName': 1, }
                weeklyEvent = mongo_db.find_one('weeklyEvent', query, fields = fields)['item']
                url = _weekly_event.GetUrl(weeklyEvent)
                body += ' ' + url
            _sms_twilio.SendToUsers(body, userIds)
    return ret
