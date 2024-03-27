from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from event import user_weekly_event as _user_weekly_event

def addRoutes():
    def Get(data, auth, websocket):
        withWeeklyEvent = data['withWeeklyEvent'] if 'withWeeklyEvent' in data else 0
        withEvent = data['withEvent'] if 'withEvent' in data else 0
        return _user_weekly_event.Get(data['weeklyEventId'], data['userId'], withWeeklyEvent, withEvent)
    _socket.add_route('GetUserWeeklyEvent', Get)

    def Save(data, auth, websocket):
        return _user_weekly_event.Save(data['userWeeklyEvent'])
    _socket.add_route('SaveUserWeeklyEvent', Save)

    # def RemoveById(data, auth, websocket):
    #     return _mongo_db_crud.RemoveById('userWeeklyEvent', data['id'])
    # _socket.add_route('removeUserWeeklyEvent', RemoveById)

addRoutes()
