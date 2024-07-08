from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from neighborhood import user_neighborhood_weekly_update as _user_neighborhood_weekly_update

def addRoutes():

    def Save(data, auth, websocket):
        return _user_neighborhood_weekly_update.Save(data['userNeighborhoodWeeklyUpdate'])
    _socket.add_route('SaveUserNeighborhoodWeeklyUpdate', Save)

    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'userId': '',
            'neighborhoodUName': '',
            'startMin': '',
            'startMax': '',
            'limit': 25,
            'skip': 0,
            'sortKeys': '-start',
            'withEventsAttendedCount': 0,
        }, data)
        equalsKeyVals = { 'userId': data['userId'], 'neighborhoodUName': data['neighborhoodUName'], }
        minKeyVals = {}
        maxKeyVals = {}
        if data['startMin'] != '':
            minKeyVals['start'] = data['startMin']
        if data['startMax'] != '':
            maxKeyVals['startMax'] = data['startMax']
        return _user_neighborhood_weekly_update.Search(equalsKeyVals, minKeyVals, maxKeyVals,
            limit = data['limit'], skip = data['skip'], sortKeys = data['sortKeys'],
            withEventsAttendedCount = data['withEventsAttendedCount'])
    _socket.add_route('SearchUserNeighborhoodWeeklyUpdates', Search)

    def GetById(data, auth, websocket):
        return _mongo_db_crud.GetById('userNeighborhoodWeeklyUpdate', data['id'])
    _socket.add_route('GetUserNeighborhoodWeeklyUpdateById', GetById)

addRoutes()
