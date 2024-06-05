from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from event import event_insight as _event_insight

def AddRoutes():
    def GetByEvent(data, auth, websocket):
        return _mongo_db_crud.Get('eventInsight', { 'eventId': data['eventId'] })
    _socket.add_route('GetEventInsightByEvent', GetByEvent)

    def AddView(data, auth, websocket):
        return _event_insight.AddEventView(data['eventId'])
    _socket.add_route('AddEventInsightView', AddView)

AddRoutes()
