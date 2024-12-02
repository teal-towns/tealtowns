from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from event import weekly_event as _weekly_event

def AddRoutesAsync():
    async def GetByIdWithData(data, auth, websocket):
        async def OnUpdate(data):
            await _socket.sendAsync(websocket, "GetWeeklyEventByIdWithData", data, auth)

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
        return await _weekly_event.GetById(data['id'], data['withAdmins'], data['withEvent'],
            data['withUserEvents'], data['withUserId'], weeklyEventUName = data['uName'],
            withEventInsight = data['withEventInsight'], userOrIP = data['userOrIP'],
            addEventView = data['addEventView'], onUpdate = OnUpdate)
    _socket.add_route('GetWeeklyEventByIdWithData', GetByIdWithData, 'async')

    async def GetById(data, auth, websocket):
        async def OnUpdate(data):
            await _socket.sendAsync(websocket, "getWeeklyEventById", data, auth)

        data = lodash.extend_object({
            'id': '',
            'uName': '',
            'userOrIP': '',
            'addEventView': 0,
        }, data)
        return await _weekly_event.GetById(data['id'], weeklyEventUName = data['uName'],
            userOrIP = data['userOrIP'], addEventView = data['addEventView'], onUpdate = OnUpdate)
    _socket.add_route('getWeeklyEventById', GetById, 'async')

    async def SearchNear(data, auth, websocket):
        async def OnUpdate(data):
            await _socket.sendAsync(websocket, 'SearchNearWeeklyEvents', data, auth)

        data = lodash.extend_object({
            'title': '',
            'limit': 1000,
            'skip': 0,
            'withAdmins': 1,
            'type': '',
            'withEvents': 0,
            'withUserEventUserId': '',
            'pending': 0,
        }, data)
        lngLat = data['lngLat']
        return await _weekly_event.SearchNear(lngLat, float(data['maxMeters']), data['title'], data['limit'], data['skip'],
            data['withAdmins'], data['type'], withEvents = data['withEvents'],
            withUserEventUserId = data['withUserEventUserId'], pending = data['pending'], onUpdate = OnUpdate)
    _socket.add_route('SearchNearWeeklyEvents', SearchNear, 'async')

def AddRoutes():
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

    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'uName': '',
            'neighborhoodUName': '',
            'title': '',
            'limit': 1000,
            'skip': 0,
            'sortKeys': '-createdAt',
        }, data)
        stringKeyVals = { 'uName': data['uName'], 'neighborhoodUName': data['neighborhoodUName'], 'title': data['title'] }
        equalsKeyVals = { 'archived': 0 }
        return _mongo_db_crud.Search('weeklyEvent', stringKeyVals = stringKeyVals, equalsKeyVals = equalsKeyVals,
            limit = data['limit'], skip = data['skip'], sortKeys = data['sortKeys'])
    _socket.add_route('SearchWeeklyEvents', Search)

    def SendWeeklyEventInvites(data, auth, websocket):
        return _weekly_event.SendInvites(data['invites'], data['weeklyEventUName'], data['userId'])
    _socket.add_route('SendWeeklyEventInvites', SendWeeklyEventInvites)

    def CheckAndSavePendingWeeklyEvents(data, auth, websocket):
        data = lodash.extend_object({
            'daysOfWeek': [],
        }, data)
        return _weekly_event.CheckAndSavePending(data['weeklyEvents'], data['userId'], data['startTimes'],
            type = data['type'], neighborhoodUName = data['neighborhoodUName'])
    _socket.add_route('CheckAndSavePendingWeeklyEvents', CheckAndSavePendingWeeklyEvents)

    def UserSubscribedOrPendingWeeklyEvents(data, auth, websocket):
        return _weekly_event.UserSubscribedOrPending(data['userId'], data['neighborhoodUName'])
    _socket.add_route('UserSubscribedOrPendingWeeklyEvents', UserSubscribedOrPendingWeeklyEvents)

AddRoutes()
AddRoutesAsync()