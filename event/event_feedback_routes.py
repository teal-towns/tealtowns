from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from event import event_feedback as _event_feedback
import websocket_clients as _websocket_clients

def AddRoutes():
    def GetByEvent(data, auth, websocket):
        withUserFeedback = data['withUserFeedback'] if 'withUserFeedback' in data else 0
        withEvent = data['withEvent'] if 'withEvent' in data else 0
        withCheckAskForFeedbackUserId = data['withCheckAskForFeedbackUserId'] if 'withCheckAskForFeedbackUserId' in data else ''
        return _event_feedback.GetByEvent(data['eventId'], withUserFeedback = withUserFeedback,
            withEvent = withEvent, withCheckAskForFeedbackUserId = withCheckAskForFeedbackUserId)
    _socket.add_route('GetEventFeedbackByEvent', GetByEvent)

    def GetByWeeklyEvent(data, auth, websocket):
        withUserFeedback = data['withUserFeedback'] if 'withUserFeedback' in data else 0
        withCheckAskForFeedbackUserId = data['withCheckAskForFeedbackUserId'] if 'withCheckAskForFeedbackUserId' in data else ''
        return _event_feedback.GetByWeeklyEvent(data['weeklyEventId'], withUserFeedback = withUserFeedback,
            withCheckAskForFeedbackUserId = withCheckAskForFeedbackUserId)
    _socket.add_route('GetEventFeedbackByWeeklyEvent', GetByWeeklyEvent)

    def Save(data, auth, websocket):
        return _mongo_db_crud.Save('eventFeedback', data['eventFeedback'])
    _socket.add_route('SaveEventFeedback', Save)

    def AddImages(data, auth, websocket):
        return _event_feedback.AddImages(data['eventFeedbackId'], data['imageUrls'])
    _socket.add_route('AddEventFeedbackImages', AddImages)

def AddRoutesAsync():
    async def AddFeedbackVote(data, auth, websocket):
        ret = _event_feedback.AddFeedbackVote(data['eventFeedbackId'], data['feedbackVote'])
        groupName = 'eventFeedback_' + ret['eventFeedback']['eventId']
        dataSend = { 'route': 'OnEventFeedback', 'auth': auth, 'data': { 'valid': 1, 'message': '', 'eventFeedback': ret['eventFeedback'] } }
        await _websocket_clients.SendToGroupsJson(dataSend, [groupName])
        # return ret
        await _socket.sendAsync(websocket, 'AddEventFeedbackVote', ret, auth)
    _socket.add_route('AddEventFeedbackVote', AddFeedbackVote, 'async')

    async def AddUserVotes(data, auth, websocket):
        ret = _event_feedback.AddUserFeedbackVotes(data['eventFeedbackId'], data['userId'], data['feedbackVoteIds'],
            data['positiveVoteIds'])
        groupName = 'eventFeedback_' + ret['eventFeedback']['eventId']
        dataSend = { 'route': 'OnEventFeedback', 'auth': auth, 'data': { 'valid': 1, 'message': '',
            'eventFeedback': ret['eventFeedback'] } }
        await _websocket_clients.SendToGroupsJson(dataSend, [groupName])
        # return ret
        await _socket.sendAsync(websocket, 'AddEventFeedbackUserVotes', ret, auth)
    _socket.add_route('AddEventFeedbackUserVotes', AddUserVotes, 'async')

    # async def RemoveUserVotes(data, auth, websocket):
    #     ret = _event_feedback.RemoveFeedbackUserVotes(data['eventFeedbackId'], data['feedbackVoteIds'],
    #         data['userId'])
    #     groupName = 'eventFeedback_' + ret['eventFeedback']['eventId']
    #     dataSend = { 'route': 'OnEventFeedback', 'auth': auth, 'data': { 'valid': 1, 'message': '', 'eventFeedback': ret['eventFeedback'] } }
    #     await _websocket_clients.SendToGroupsJson(dataSend, [groupName])
    #     # return ret
    #     await _socket.sendAsync(websocket, 'RemoveEventFeedbackUserVotes', ret, auth)
    # _socket.add_route('RemoveEventFeedbackUserVotes', RemoveUserVotes, 'async')

    async def AddPositiveVote(data, auth, websocket):
        ret = _event_feedback.AddPositiveVote(data['eventFeedbackId'], data['positiveVote'])
        groupName = 'eventFeedback_' + ret['eventFeedback']['eventId']
        dataSend = { 'route': 'OnEventFeedback', 'auth': auth, 'data': { 'valid': 1, 'message': '',
            'eventFeedback': ret['eventFeedback'] } }
        await _websocket_clients.SendToGroupsJson(dataSend, [groupName])
        # return ret
        await _socket.sendAsync(websocket, 'AddEventPositiveVote', ret, auth)
    _socket.add_route('AddEventPositiveVote', AddPositiveVote, 'async')

AddRoutes()
AddRoutesAsync()
