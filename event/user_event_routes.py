from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from event import user_event as _user_event

def addRoutes():
    def Get(data, auth, websocket):
        withEvent = data['withEvent'] if 'withEvent' in data else 0
        withUserCheckPayment = data['withUserCheckPayment'] if 'withUserCheckPayment' in data else 0
        withWeeklyEvent = data['withWeeklyEvent'] if 'withWeeklyEvent' in data else 0
        return _user_event.Get(data['eventId'], data['userId'], withEvent, withUserCheckPayment,
            withWeeklyEvent)
    _socket.add_route('GetUserEvent', Get)

    def Save(data, auth, websocket):
        return _user_event.Save(data['userEvent'], data['payType'])
    _socket.add_route('SaveUserEvent', Save)

    # def RemoveById(data, auth, websocket):
    #     return _mongo_db_crud.RemoveById('userEvent', data['id'])
    # _socket.add_route('removeUserEvent', RemoveById)

    def GetUsers(data, auth, websocket):
        return _user_event.GetUsers(data['eventId'])
    _socket.add_route('GetUserEventUsers', GetUsers)

    def GetStats(data, auth, websocket):
        withUserId = data['withUserId'] if 'withUserId' in data else ''
        return _user_event.GetStats(data['eventId'], withUserId)
    _socket.add_route('GetUserEventStats', GetStats)

addRoutes()
