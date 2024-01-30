from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from event import weekly_event as _weekly_event

def addRoutes():
    def GetById(data, auth, websocket):
        data = lodash.extend_object({
            'withHosts': 0,
        }, data)
        return _weekly_event.GetById(data['id'], data['withHosts'])
    _socket.add_route('getWeeklyEventById', GetById)

    def Save(data, auth, websocket):
        return _mongo_db_crud.Save('weeklyEvent', data['weeklyEvent'])
    _socket.add_route('saveWeeklyEvent', Save)

    def RemoveById(data, auth, websocket):
        return _mongo_db_crud.RemoveById('weeklyEvent', data['id'])
    _socket.add_route('removeWeeklyEvent', RemoveById)

    def SearchNear(data, auth, websocket):
        data = lodash.extend_object({
            'title': '',
            'limit': 250,
            'skip': 0,
            'withHosts': 1,
        }, data)
        lngLat = data['lngLat']
        return _weekly_event.SearchNear(lngLat, float(data['maxMeters']), data['title'], data['limit'], data['skip'],
            data['withHosts'])
    _socket.add_route('searchWeeklyEvents', SearchNear)

addRoutes()
