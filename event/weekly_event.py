import asyncio
import threading
import time

from common import location as _location
from common import math_polygon as _math_polygon
from common import mongo_db_crud as _mongo_db_crud
import date_time
from event import event as _event
from event import event_insight as _event_insight
from event import event_payment as _event_payment
from event import user_event as _user_event
from event import user_weekly_event as _user_weekly_event
from user_payment import user_payment as _user_payment
import lodash
import log
import mongo_db
import ml_config

_config = ml_config.get_config()

def SearchNear(lngLat: list, maxMeters: float = 500, title: str = '', limit: int = 250, skip: int = 0, withAdmins: int = 1,
    type: str = '', archived: int = 0):
    query = {}
    if len(lngLat) > 0:
        query = {
            'location': {
                '$nearSphere': {
                    '$geometry': {
                        'type': 'Point',
                        'coordinates': lngLat,
                    },
                    '$maxDistance': maxMeters,
                }
            },
        }
    sortKeys = "dayOfWeek,startTime"
    ret = _mongo_db_crud.Search('weeklyEvent', {'title': title, 'type': type}, equalsKeyVals = {'archived': archived},
        limit = limit, skip = skip, query = query, sortKeys = sortKeys)
    userIds = []
    # Calculate distance
    # May also be able to use geoNear https://stackoverflow.com/questions/33864461/mongodb-print-distance-between-two-points
    for index, item in reversed(list(enumerate(ret['weeklyEvents']))):
        if len(lngLat) > 0:
            ret['weeklyEvents'][index]['xDistanceKm'] = round(_math_polygon.Haversine(item['location']['coordinates'],
                lngLat, units = 'kilometers'), 3)
        if withAdmins:
            for userId in item['adminUserIds']:
                if userId not in userIds:
                    userIds.append(userId)

    if len(userIds) > 0 and withAdmins:
        listKeyVals = { '_id': userIds }
        fields = { "firstName": 1, "lastName": 1, "email": 1, }
        users = _mongo_db_crud.Search('user', listKeyVals = listKeyVals, fields = fields, limit = limit * 10)['users']
        usersIdMap = {}
        for user in users:
            usersIdMap[user['_id']] = user
        for indexEvent, event in enumerate(ret['weeklyEvents']):
            if 'adminUsers' not in ret['weeklyEvents'][indexEvent]:
                ret['weeklyEvents'][indexEvent]['adminUsers'] = []
            for userId in event['adminUserIds']:
                user = usersIdMap[userId] if userId in usersIdMap else {}
                ret['weeklyEvents'][indexEvent]['adminUsers'].append(user)

    return ret

async def GetById(weeklyEventId: str, withAdmins: int = 1, withEvent: int = 0, withUserEvents: int = 0,
    withUserId: str = '', weeklyEventUName: str = '', withEventInsight: int = 0, userOrIP: str = '',
    addEventView: int = 1, onUpdate = None):
    ret = _mongo_db_crud.GetById('weeklyEvent', weeklyEventId, uName = weeklyEventUName)
    if not ret['valid'] or '_id' not in ret['weeklyEvent']:
        return ret
    if len(weeklyEventId) < 1:
        weeklyEventId = ret['weeklyEvent']['_id']
    if withAdmins:
        userIds = []
        for userId in ret['weeklyEvent']['adminUserIds']:
            if userId not in userIds:
                userIds.append(userId)
        listKeyVals = { '_id': userIds }
        fields = { "firstName": 1, "lastName": 1, "email": 1, }
        users = _mongo_db_crud.Search('user', listKeyVals = listKeyVals, fields = fields)['users']
        usersIdMap = {}
        for user in users:
            usersIdMap[user['_id']] = user
        ret['weeklyEvent']['adminUsers'] = []
        for userId in ret['weeklyEvent']['adminUserIds']:
            user = usersIdMap[userId] if userId in usersIdMap else {}
            ret['weeklyEvent']['adminUsers'].append(user)
    if onUpdate:
        await onUpdate(ret)
        await asyncio.sleep(0)

    if withEvent:
        retEvents = _event.GetNextEvents(weeklyEventId, minHoursBeforeRsvpDeadline = 0)
        ret['event'] = retEvents['nextWeekEvent'] if retEvents['rsvpDeadlinePassed'] else retEvents['thisWeekEvent']
        ret['rsvpDeadlinePassed'] = retEvents['rsvpDeadlinePassed']
        ret['nextEvent'] = retEvents['nextWeekEvent']
        if onUpdate:
            await onUpdate(ret)
            await asyncio.sleep(0)
        if withUserEvents and '_id' in ret['event']:
            retStats = _user_event.GetStats(ret['event']['_id'], withUserId = withUserId)
            ret['attendeesCount'] = retStats['attendeesCount']
            ret['attendeesWaitingCount'] = retStats['attendeesWaitingCount']
            ret['nonHostAttendeesWaitingCount'] = retStats['nonHostAttendeesWaitingCount']
            ret['userEvent'] = retStats['userEvent']
        else:
            ret['userEvent'] = {}
        if withEventInsight and '_id' in ret['event']:
            ret['eventInsight'] = _event_insight.GetByEvent(ret['event']['_id'], addEventView = addEventView,
                userOrIP = userOrIP)['eventInsight']
        else:
            ret['eventInsight'] = {}

    if onUpdate:
        await onUpdate(ret)
    return ret

def Save(weeklyEvent: dict):
    weeklyEvent = _mongo_db_crud.CleanId(weeklyEvent)
    if '_id' not in weeklyEvent:
        # Many weekly events will have the same title, so just use blank string to keep them shorter.
        weeklyEvent['uName'] = lodash.CreateUName('')
        if weeklyEvent['priceUSD'] > 0 and weeklyEvent['priceUSD'] < 5:
            if weeklyEvent['priceUSD'] < 2.5:
                weeklyEvent['priceUSD'] = 0
            else:
                weeklyEvent['priceUSD'] = 5
    else:
        # Some field changes require other updates.
        weeklyEventExisting = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEvent['_id'])})['item']
        if weeklyEventExisting:
            # Give credits to existing users who have subscribed.
            if weeklyEvent['priceUSD'] != weeklyEventExisting['priceUSD'] and \
                weeklyEventExisting['priceUSD'] > 0:
                EndSubscriptions(weeklyEventExisting['_id'])
    if 'timezone' not in weeklyEvent or weeklyEvent['timezone'] == '':
        weeklyEvent['timezone'] = date_time.GetTimezoneFromLngLat(weeklyEvent['location']['coordinates'])
    if 'locationAddress' not in weeklyEvent or len(weeklyEvent['locationAddress']) < 1 or \
        'street' not in weeklyEvent['locationAddress'] or len(weeklyEvent['locationAddress']['street']) < 1:
        weeklyEvent['locationAddress'] = _location.LngLatToAddress(weeklyEvent['location']['coordinates'][0],
            weeklyEvent['location']['coordinates'][1])['address']
    payInfo = _event_payment.GetSubscriptionDiscounts(weeklyEvent['priceUSD'], weeklyEvent['hostGroupSizeDefault'])
    weeklyEvent['hostMoneyPerPersonUSD'] = payInfo['eventFunds']
    return _mongo_db_crud.Save('weeklyEvent', weeklyEvent)

def SaveBulk(weeklyEvents: list):
    ret = { 'valid': 1, 'message': '', 'weeklyEvents': [], }
    for weeklyEvent in weeklyEvents:
        weeklyEvent['dayOfWeek'] = int(weeklyEvent['dayOfWeek'])
        retOne = Save(weeklyEvent)
        if retOne['valid']:
            ret['weeklyEvents'].append(retOne['weeklyEvent'])
        else:
            ret['message'] += retOne['message']
    if len(ret['weeklyEvents']) < 1:
        ret['valid'] = 0
    return ret

def EndSubscriptions(weeklyEventId):
    ret = { 'valid': 1, 'message': '' }
    # End stripe subscription
    query = { 'forId': weeklyEventId, 'forType': 'weeklyEvent' }
    userPaymentSubscriptions = mongo_db.find('userPaymentSubscription', query)['items']
    for userPaymentSubscription in userPaymentSubscriptions:
        _user_payment.CancelSubscription(userPaymentSubscription['_id'])
    # Already done individually IF were paid events.
    mongo_db.delete_many('userWeeklyEvent', { 'weeklyEventId': weeklyEventId })
    return ret

def Remove(weeklyEventId: str):
    # Soft delete to preserve stats.
    # query = { 'weeklyEventId': weeklyEventId }
    # events = mongo_db.find('event', query)['items']
    # eventIds = []
    # for event in events:
    #     eventIds.append(event['_id'])
    # mongo_db.delete_many('userEvent', { 'eventId': { '$in': eventIds } })

    # mongo_db.delete_many('event', { 'weeklyEventId': weeklyEventId })

    EndSubscriptions(weeklyEventId)

    # return _mongo_db_crud.RemoveById('weeklyEvent', weeklyEventId)
    mutation = { '$set': { 'archived': 1 } }
    query = { '_id': mongo_db.to_object_id(weeklyEventId) }
    mongo_db.update_one('weeklyEvent', query, mutation)
    return { 'valid': 1, 'message': '', }

def CheckRSVPDeadline(weeklyEventId: str, now = None):
    ret = { 'valid': 1, 'message': '', 'newUserEvents': [], 'notifyUserIdsSubscribers': {},
        'notifyUserIdsHosts': {}, 'notifyUserIdsAttendees': {}, 'notifyUserIdsUnused': {}, }
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    if not weeklyEvent['archived']:
        retCheck = _event.GetNextEventStart(weeklyEvent, now = now)
        # See if deadline passed.
        if retCheck['rsvpDeadlinePassed']:
            # See if this is the first time passed (most recent event is still this week's event).
            sortObj = { 'start': -1 }
            events = mongo_db.find('event', {'weeklyEventId': weeklyEvent['_id']}, sort_obj = sortObj)['items']
            if len(events) > 0:
                currentEvent = events[0]
                if currentEvent['start'] == retCheck['thisWeekStart']:
                    retAdd = _user_event.CheckAddHostsAndAttendees(currentEvent['_id'], fillAll = 1)
                    ret['notifyUserIdsUnused'] = retAdd['notifyUserIdsUnused']
                    ret['notifyUserIdsAttendees'] = retAdd['notifyUserIdsAttendees']
                    ret['notifyUserIdsHosts'] = retAdd['notifyUserIdsHosts']
                    retUsers = _user_weekly_event.AddWeeklyUsersToEvent(weeklyEvent['_id'], now = now)
                    ret['newUserEvents'] = retUsers['newUserEvents']
                    ret['notifyUserIdsSubscribers'] = retUsers['notifyUserIds']
    return ret

def CheckAllRSVPDeadlines(now = None):
    query = { 'priceUSD': { '$gt': 0 } }
    weeklyEvents = mongo_db.find('weeklyEvent', query)['items']
    log.log('info', 'weekly_event.CheckAllRSVPDeadlines', str(len(weeklyEvents)), 'weekly events')
    for weeklyEvent in weeklyEvents:
        CheckRSVPDeadline(weeklyEvent['_id'], now = now)
    return None

def CheckRSVPDeadlineLoop(timeoutMinutes = 15):
    log.log('info', 'weekly_event.CheckRSVPDeadlineLoop starting')
    thread = None
    while 1:
        if thread is None or not thread.is_alive():
            thread = threading.Thread(target=CheckAllRSVPDeadlines, args=())
            thread.start()
        time.sleep(timeoutMinutes * 60)
    return None

def GetUrl(weeklyEvent: dict):
    return _config['web_server']['urls']['base'] + '/we/' + str(weeklyEvent['uName'])
