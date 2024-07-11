from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from event import event as _event

def addRoutes():
    def GetById(data, auth, websocket):
        data = lodash.extend_object({
            'withAdmins': 0,
            'withUserEvents': 0,
            'withUserId': '',
            'id': '',
            'uName': '',
        }, data)
        return _event.GetById(data['id'], data['withAdmins'],
            data['withUserEvents'], data['withUserId'], eventUName = data['uName'])
    _socket.add_route('GetEventById', GetById)

    # def GetByIds(data, auth, websocket):
    #     return _event.GetByIds(data['ids'])
    # _socket.add_route('GetEventsByIds', GetByIds)

    def GetEventWithWeekly(data, auth, websocket):
        return _event.GetEventWithWeekly(data['eventId'])
    _socket.add_route('GetEventWithWeekly', GetEventWithWeekly)

    # def Save(data, auth, websocket):
    #     return _event.Save(data['event'])
    # _socket.add_route('SaveEvent', Save)

    def RemoveById(data, auth, websocket):
        return _event.Remove(data['id'])
    _socket.add_route('RemoveEvent', RemoveById)

    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'title': '',
            'limit': 250,
            'skip': 0,
            'type': '',
            'location': {},
            'withLocationDistance': 0,
        }, data)
        return _mongo_db_crud.Search('event', stringKeyVals = { 'title': data['title'], },
            locationKeyVals = { 'location': data['location'], }, limit = data['limit'], skip = data['skip'],
            withLocationDistance = data['withLocationDistance'],)
    _socket.add_route('SearchEvents', Search)

addRoutes()
