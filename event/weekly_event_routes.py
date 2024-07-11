from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from event import weekly_event as _weekly_event

def addRoutes():
    def GetByIdWithData(data, auth, websocket):
        data = lodash.extend_object({
            'withAdmins': 0,
            'withEvent': 0,
            'withUserEvents': 0,
            'withUserId': '',
            'withEventInsight': 0,
            'id': '',
            'uName': '',
            'userOrIP': '',
            'addEventView': 0,
        }, data)
        return _weekly_event.GetById(data['id'], data['withAdmins'], data['withEvent'],
            data['withUserEvents'], data['withUserId'], weeklyEventUName = data['uName'],
            withEventInsight = data['withEventInsight'], userOrIP = data['userOrIP'],
            addEventView = data['addEventView'])
    _socket.add_route('GetWeeklyEventByIdWithData', GetByIdWithData)

    def GetById(data, auth, websocket):
        data = lodash.extend_object({
            'id': '',
            'uName': '',
            'userOrIP': '',
            'addEventView': 0,
        }, data)
        return _weekly_event.GetById(data['id'], weeklyEventUName = data['uName'],
            userOrIP = data['userOrIP'], addEventView = data['addEventView'])
    _socket.add_route('getWeeklyEventById', GetById)

    def Save(data, auth, websocket):
        data['weeklyEvent']['dayOfWeek'] = int(data['weeklyEvent']['dayOfWeek'])
        return _weekly_event.Save(data['weeklyEvent'])
    _socket.add_route('saveWeeklyEvent', Save)

    def SaveBulk(data, auth, websocket):
        return _weekly_event.SaveBulk(data['weeklyEvents'])
    _socket.add_route('SaveWeeklyEvents', SaveBulk)

    def RemoveById(data, auth, websocket):
        return _weekly_event.Remove(data['id'])
    _socket.add_route('removeWeeklyEvent', RemoveById)

    def SearchNear(data, auth, websocket):
        data = lodash.extend_object({
            'title': '',
            'limit': 250,
            'skip': 0,
            'withAdmins': 1,
            'type': '',
        }, data)
        lngLat = data['lngLat']
        return _weekly_event.SearchNear(lngLat, float(data['maxMeters']), data['title'], data['limit'], data['skip'],
            data['withAdmins'], data['type'])
    _socket.add_route('SearchNearWeeklyEvents', SearchNear)

    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'uName': '',
            'neighborhoodUName': '',
            'title': '',
            'limit': 250,
            'skip': 0,
            'sortKeys': '-createdAt',
        }, data)
        stringKeyVals = { 'uName': data['uName'], 'neighborhoodUName': data['neighborhoodUName'], 'title': data['title'] }
        equalsKeyVals = { 'archived': 0 }
        return _mongo_db_crud.Search('weeklyEvent', stringKeyVals = stringKeyVals, equalsKeyVals = equalsKeyVals,
            limit = data['limit'], skip = data['skip'], sortKeys = data['sortKeys'])
    _socket.add_route('SearchWeeklyEvents', Search)

addRoutes()
