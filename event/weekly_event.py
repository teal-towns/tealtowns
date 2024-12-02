import asyncio
import copy
import re
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
from notifications_all import sms_twilio as _sms_twilio
from notifications_all import email_sendgrid as _email_sendgrid
from user_auth import user as _user
from user_payment import user_payment as _user_payment
import lodash
import log
import mongo_db
import ml_config

_config = ml_config.get_config()

def SearchNearSync(lngLat: list, maxMeters: float = 500, title: str = '', limit: int = 250, skip: int = 0, withAdmins: int = 1,
    type: str = '', archived: int = 0, withEvents: int = 0, pending: int = 0, now = None):
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
    equalsKeyVals = {'archived': archived}
    if not pending:
        equalsKeyVals['pendingUsers'] = []
    ret = _mongo_db_crud.Search('weeklyEvent', {'title': title, 'type': type}, equalsKeyVals = equalsKeyVals,
        limit = limit, skip = skip, query = query, sortKeys = sortKeys)
    userIds = []
    weeklyEventIds = []
    weeklyEventIdsMap = {}
    # Calculate distance
    # May also be able to use geoNear https://stackoverflow.com/questions/33864461/mongodb-print-distance-between-two-points
    for index, item in reversed(list(enumerate(ret['weeklyEvents']))):
        weeklyEventIdsMap[item['_id']] = index
        if withEvents:
            weeklyEventIds.append(item['_id'])
        if len(lngLat) > 0:
            ret['weeklyEvents'][index]['xDistanceKm'] = round(_math_polygon.Haversine(item['location']['coordinates'],
                lngLat, units = 'kilometers'), 3)
        if withAdmins:
            for userId in item['adminUserIds']:
                if userId not in userIds:
                    userIds.append(userId)
    ret['userIds'] = userIds
    ret['weeklyEventIds'] = weeklyEventIds
    ret['weeklyEventIdsMap'] = weeklyEventIdsMap
    return ret

async def SearchNear(lngLat: list, maxMeters: float = 500, title: str = '', limit: int = 250, skip: int = 0, withAdmins: int = 1,
    type: str = '', archived: int = 0, withEvents: int = 0, pending: int = 0, withUserEventUserId: str = '', now = None, onUpdate = None,
    autoCreateEvents: int = 1):
    ret = SearchNearSync(lngLat, maxMeters, title, limit, skip, withAdmins = withAdmins,
        type = type, archived = archived, withEvents = withEvents, pending = pending, now = now)
    userIds = ret['userIds']
    weeklyEventIds = ret['weeklyEventIds']
    weeklyEventIdsMap = ret['weeklyEventIdsMap']
    del ret['userIds']
    del ret['weeklyEventIds']
    del ret['weeklyEventIdsMap']

    if onUpdate:
        await onUpdate(ret)
        await asyncio.sleep(0)

    if len(weeklyEventIds) > 0 and withEvents:
        now = now if now is not None else date_time.now()
        query = { 'weeklyEventId': { '$in': weeklyEventIds }, 'start': { '$gt': date_time.string(now) } }
        fields = { 'userEventsAttendeeCache': 1, 'weeklyEventId': 1, 'start': 1, 'end': 1,
            'neighborhoodUName': 1, 'weeklyEventUName': 1, }
        events = mongo_db.find('event', query, fields = fields)['items']
        eventIdToWeeklyEventIdMap = {}
        eventIds = []
        missingEventWeeklyEventIds = copy.deepcopy(weeklyEventIds)
        for event in events:
            eventIds.append(event['_id'])
            eventIdToWeeklyEventIdMap[event['_id']] = event['weeklyEventId']
            ret['weeklyEvents'][weeklyEventIdsMap[event['weeklyEventId']]]['xEvent'] = event
            if autoCreateEvents and event['weeklyEventId'] in missingEventWeeklyEventIds:
                missingEventWeeklyEventIds.remove(event['weeklyEventId'])

        if autoCreateEvents and len(missingEventWeeklyEventIds) > 0:
            for weeklyEventId in missingEventWeeklyEventIds:
                weeklyEvent = ret['weeklyEvents'][weeklyEventIdsMap[weeklyEventId]]
                retNext = _event.GetNextEventFromWeekly(weeklyEventId, weeklyEvent = weeklyEvent, now = now, autoCreate = 1)
                if len(retNext['event']['_id']) > 0:
                    event = retNext['event']
                    eventIds.append(event['_id'])
                    eventIdToWeeklyEventIdMap[event['_id']] = event['weeklyEventId']
                    ret['weeklyEvents'][weeklyEventIdsMap[event['weeklyEventId']]]['xEvent'] = event

        if onUpdate:
            await onUpdate(ret)
            await asyncio.sleep(0)
        if len(withUserEventUserId) > 0:
            query = { 'eventId': { '$in': eventIds }, 'userId': withUserEventUserId }
            userEvents = mongo_db.find('userEvent', query)['items']
            for userEvent in userEvents:
                ret['weeklyEvents'][weeklyEventIdsMap[eventIdToWeeklyEventIdMap[userEvent['eventId']]]]['xUserEvent'] = userEvent
            if onUpdate:
                await onUpdate(ret)
                await asyncio.sleep(0)

    if len(userIds) > 0 and withAdmins:
        listKeyVals = { '_id': userIds }
        fields = { "firstName": 1, "lastName": 1, "email": 1,
            'phoneNumber': 1, 'phoneNumberVerified': 1, 'whatsappNumber': 1, 'whatsappNumberVerified': 1, }
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
        if onUpdate:
            await onUpdate(ret)
            await asyncio.sleep(0)

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
        fields = { "firstName": 1, "lastName": 1, "email": 1,
            'phoneNumber': 1, 'phoneNumberVerified': 1, 'whatsappNumber': 1, 'whatsappNumberVerified': 1, }
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
    weeklyEvent = ValidateWeeklyEvent(weeklyEvent)
    return _mongo_db_crud.Save('weeklyEvent', weeklyEvent)

def ValidateWeeklyEvent(weeklyEvent: dict):
    weeklyEvent = _mongo_db_crud.CleanId(weeklyEvent)
    if '_id' not in weeklyEvent:
        # Many weekly events will have the same title, so just use blank string to keep them shorter.
        weeklyEvent['uName'] = lodash.CreateUName('')
        weeklyEvent = lodash.extend_object({
            'type': '',
            'tags': [],
            'rsvpDeadlineHours': 0,
            'imageUrls': [],
            'archived': 0,
            'pendingUsers': [],
        }, weeklyEvent)
        if weeklyEvent['priceUSD'] > 0 and weeklyEvent['priceUSD'] < 5:
            if weeklyEvent['priceUSD'] < 2.5:
                weeklyEvent['priceUSD'] = 0
            else:
                weeklyEvent['priceUSD'] = 5
        if 'endTime' not in weeklyEvent or len(weeklyEvent['endTime']) < 1:
            weeklyEvent['endTime'] = date_time.AddHoursString(weeklyEvent['startTime'], 1)
    else:
        # Some field changes require other updates.
        weeklyEventExisting = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEvent['_id'])})['item']
        if weeklyEventExisting:
            # Give credit to existing users who have subscribed.
            if weeklyEvent['priceUSD'] != weeklyEventExisting['priceUSD'] and \
                weeklyEventExisting['priceUSD'] > 0:
                EndSubscriptions(weeklyEventExisting['_id'])
    if 'timezone' not in weeklyEvent or weeklyEvent['timezone'] == '':
        weeklyEvent['timezone'] = date_time.GetTimezoneFromLngLat(weeklyEvent['location']['coordinates'])
    if 'locationAddress' not in weeklyEvent or len(weeklyEvent['locationAddress']) < 1 or \
        'street' not in weeklyEvent['locationAddress'] or len(weeklyEvent['locationAddress']['street']) < 1:
        weeklyEvent['locationAddress'] = _location.LngLatToAddress(weeklyEvent['location']['coordinates'][0],
            weeklyEvent['location']['coordinates'][1])['address']
    if 'startTime' in weeklyEvent:
        weeklyEvent['startTime'] = date_time.ToHourMinute(weeklyEvent['startTime'])
    if 'endTime' in weeklyEvent:
        weeklyEvent['endTime'] = date_time.ToHourMinute(weeklyEvent['endTime'])
    payInfo = _event_payment.GetSubscriptionDiscounts(weeklyEvent['priceUSD'], weeklyEvent['hostGroupSizeDefault'])
    weeklyEvent['hostMoneyPerPersonUSD'] = payInfo['eventFunds']
    return weeklyEvent

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

def GetUrlUName(uName: str):
    return _config['web_server']['urls']['base'] + '/we/' + str(uName)

def SendInvites(invites: list, weeklyEventUName: str, userId: str):
    ret = { 'valid': 1, 'message': '', 'smsAttemptCount': 0, 'emailAttemptCount': 0 }
    query = { '_id': mongo_db.to_object_id(userId) }
    fields = { 'firstName': 1, 'lastName': 1 }
    user = mongo_db.find_one('user', query, fields = fields)['item']
    body = user['firstName'] + ' invited you to an event! ' + GetUrlUName(weeklyEventUName)
    messageTemplateVariables = { "1": user['firstName'], "2": GetUrlUName(weeklyEventUName) }
    regex = re.compile('[^0-9 ]')
    for invite in invites:
        contactType = _user.GuessContactType(invite)
        if contactType == 'phone':
            phoneNumber = regex.sub('', invite)
            retSms = _sms_twilio.Send(body, phoneNumber, mode = 'sms',
                messageTemplateKey = 'eventInvite', messageTemplateVariables = messageTemplateVariables)
            ret['smsAttemptCount'] += 1
        elif contactType == 'email':
            _email_sendgrid.Send(user['firstName'] + ' invited you to an event!', body, invite)
            ret['emailAttemptCount'] += 1
    return ret

def GetByTimes(startTimes: list, daysOfWeek: list = [], type: str = '', neighborhoodUName: str = ''):
    ret = { 'valid': 1, 'message': '', 'weeklyEvents': [], }
    query = { 'startTime': { '$in': startTimes } }
    if len(daysOfWeek) > 0:
        query['dayOfWeek'] = { '$in': daysOfWeek }
    if len(type) > 0:
        query['type'] = type
    if len(neighborhoodUName) > 0:
        query['neighborhoodUName'] = neighborhoodUName
    sort = { 'dayOfWeek': 1, 'startTime': 1 }
    ret['weeklyEvents'] = mongo_db.find('weeklyEvent', query, sort_obj = sort)['items']
    return ret

def CheckAndSavePending(weeklyEventsNew: list, userId: str, startTimes: list, daysOfWeek: list = [], type: str = '',
    neighborhoodUName: str = ''):
    ret = { 'valid': 1, 'message': '', 'weeklyEventsCreated': [], 'weeklyEventUNamesToJoin': [], 'notifyUserIds': { 'sms': [], 'email': [] }, }
    weeklyEvents = GetByTimes(startTimes, daysOfWeek = daysOfWeek, type = type,
        neighborhoodUName = neighborhoodUName)['weeklyEvents']
    # Both should be sorted.
    weeklyEventsIndex = 0
    maxIndex = len(weeklyEvents)
    weeklyEventsSave = []

    location = {}
    if 'location' not in weeklyEventsNew[0] and neighborhoodUName != '':
        neighborhood = mongo_db.find_one('neighborhood', {'uName': neighborhoodUName})['item']
        location = neighborhood['location']

    for weeklyEvent in weeklyEventsNew:
        while weeklyEventsIndex < maxIndex and (weeklyEvents[weeklyEventsIndex]['dayOfWeek'] < weeklyEvent['dayOfWeek'] or \
            (weeklyEvents[weeklyEventsIndex]['dayOfWeek'] == weeklyEvent['dayOfWeek'] and \
            weeklyEvents[weeklyEventsIndex]['startTime'] < weeklyEvent['startTime'])):
            weeklyEventsIndex += 1
        # Weekly event already exists. Add pending user (if not already pending).
        if weeklyEventsIndex < maxIndex and weeklyEvents[weeklyEventsIndex]['dayOfWeek'] == weeklyEvent['dayOfWeek'] and \
            weeklyEvents[weeklyEventsIndex]['startTime'] == weeklyEvent['startTime']:
            # If event is already created (no longer pending), can sign up for them (may require payment, so cannnot do it here).
            if len(weeklyEvents[weeklyEventsIndex]['pendingUsers']) < 1:
                ret['weeklyEventUNamesToJoin'].append(weeklyEvents[weeklyEventsIndex]['uName'])
                continue
            # Ensure user is not already pending.
            addNew = 1
            for pendingUser in weeklyEvents[weeklyEventsIndex]['pendingUsers']:
                if pendingUser['userId'] == userId:
                    addNew = 0
                    break
            if addNew:
                # Plus 1 as we will add this user.
                totalPending = len(weeklyEvents[weeklyEventsIndex]['pendingUsers']) + 1
                # If now have enough pending users, change them all to admins and send invites.
                if totalPending >= weeklyEvents[weeklyEventsIndex]['hostGroupSizeDefault']:
                    # Send to current user and then all existing pending users.
                    userIds = [userId]
                    retNotify = NotifyUserOfEventActive(userId, weeklyEvents[weeklyEventsIndex]['uName'])
                    ret['notifyUserIds']['sms'] += retNotify['notifyUserIds']['sms']
                    ret['notifyUserIds']['email'] += retNotify['notifyUserIds']['email']
                    for pendingUser in weeklyEvents[weeklyEventsIndex]['pendingUsers']:
                        userIds.append(pendingUser['userId'])
                        # Send invites.
                        retNotify = NotifyUserOfEventActive(pendingUser['userId'], weeklyEvents[weeklyEventsIndex]['uName'])
                        ret['notifyUserIds']['sms'] += retNotify['notifyUserIds']['sms']
                        ret['notifyUserIds']['email'] += retNotify['notifyUserIds']['email']
                    mutation = { '$set': { 'adminUserIds': userIds, 'pendingUsers': [] } }
                    mongo_db.update_one('weeklyEvent', { '_id': mongo_db.to_object_id(weeklyEvents[weeklyEventsIndex]['_id']) }, mutation)
                else:
                    pendingUserNew = {}
                    for pendingUser in weeklyEvent['pendingUsers']:
                        if pendingUser['userId'] == userId:
                            pendingUserNew = pendingUser
                            mutation = { '$push': { 'pendingUsers': pendingUserNew } }
                            mongo_db.update_one('weeklyEvent', { '_id': mongo_db.to_object_id(weeklyEvents[weeklyEventsIndex]['_id']) }, mutation)
                            break
        # Create new weekly event.
        else:
            if 'location' not in weeklyEvent:
                weeklyEvent['location'] = location
            weeklyEventsSave.append(ValidateWeeklyEvent(weeklyEvent))
    if len(weeklyEventsSave) > 0:
        ret['weeklyEventsCreated'] = mongo_db.insert_many('weeklyEvent', weeklyEventsSave)['items']
    return ret

def NotifyUserOfEventActive(userId: str, weeklyEventUName: str):
    ret = { 'valid': 1, 'message': '', 'notifyUserIds': { 'sms': [], 'email': [] }, }
    retPhone = _user.GetPhone(userId)
    body = 'Your pending event is now active! Sign up here: ' + GetUrlUName(weeklyEventUName)
    if retPhone['valid']:
        messageTemplateVariables = { "1": GetUrlUName(weeklyEventUName) }
        retSms = _sms_twilio.Send(body, retPhone['phoneNumber'], mode = retPhone['mode'],
            messageTemplateKey = 'eventPendingMatch', messageTemplateVariables = messageTemplateVariables)
        ret['notifyUserIds']['sms'].append(retPhone['userId'])
    elif len(retPhone['email']) > 0:
        body = ''
        retEmail = _email_sendgrid.Send('Pending Event is now Active!', body, retPhone['email'])
        ret['notifyUserIds']['email'].append(retPhone['userId'])
    return ret

def UserSubscribedOrPending(userId: str, neighborhoodUName: str):
    ret = { 'valid': 1, 'message': '', 'alreadySubscribed': 0, }

    query = { 'userId': userId }
    items = mongo_db.find('userWeeklyEvent', query)['items']
    if len(items) > 0:
        ret['alreadySubscribed'] = 1
        ret['userWeeklyEventsCount'] = len(items)
        return ret
    
    query = { 'neighborhoodUName': neighborhoodUName, 'archived': 0 }
    fields = { 'uName': 1,'pendingUsers': 1 }
    items = mongo_db.find('weeklyEvent', query, fields = fields)['items']
    for item in items:
        for pendingUser in item['pendingUsers']:
            if pendingUser['userId'] == userId:
                ret['alreadySubscribed'] = 1
                ret['weeklyEvent'] = item
                return ret

    return ret
