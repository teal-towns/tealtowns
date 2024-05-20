import lodash
from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from event import user_feedback as _user_feedback

def addRoutes():
    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'userId': '',
            'forType': '',
            'forId': '',
            'limit': 250,
            'skip': 0,
        }, data)
        stringKeyVals = { 'userId': data['userId'], 'forType': data['forType'], 'forId': data['forId'], }
        return _mongo_db_crud.Search('userFeedback', stringKeyVals = stringKeyVals,
            limit = data['limit'], skip = data['skip'],)
    _socket.add_route('SearchEvents', Search)

    def Save(data, auth, websocket):
        return _user_feedback.Save(data['userFeedback'])
    _socket.add_route('SaveUserFeedback', Save)

    def GetByEvent(data, auth, websocket):
        return _mongo_db_crud.Get('userFeedback', { 'forType': 'event', 'forId': data['eventId'] })
    _socket.add_route('GetUserFeedbackByEvent', GetByEvent)

    def CheckAskForFeedback(data, auth, websocket):
        eventId = data['eventId'] if 'eventId' in data else ''
        return _user_feedback.CheckAskForFeedback(data['userId'], eventId = eventId)
    _socket.add_route('UserCheckAskForFeedback', CheckAskForFeedback)

addRoutes()
