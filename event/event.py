import datetime
import pytz

from common import mongo_db_crud as _mongo_db_crud
import date_time
import lodash
import mongo_db
from event import event_payment as _event_payment
from event import user_event as _user_event

def GetById(eventId: str, withAdmins: int = 1, withUserEvents: int = 0,
    withUserId: str = '', eventUName: str = ''):
    ret = _mongo_db_crud.GetById('event', eventId, uName = eventUName)
    if not ret['valid'] or '_id' not in ret['event']:
        return ret
    if len(eventId) < 1:
        eventId = ret['event']['_id']
    if withAdmins:
        userIds = []
        for userId in ret['event']['adminUserIds']:
            if userId not in userIds:
                userIds.append(userId)
        listKeyVals = { '_id': userIds }
        fields = { "firstName": 1, "lastName": 1, "email": 1,
            'phoneNumber': 1, 'phoneNumberVerified': 1, 'whatsappNumber': 1, 'whatsappNumberVerified': 1, }
        users = _mongo_db_crud.Search('user', listKeyVals = listKeyVals, fields = fields)['users']
        usersIdMap = {}
        for user in users:
            usersIdMap[user['_id']] = user
        ret['event']['adminUsers'] = []
        for userId in ret['event']['adminUserIds']:
            user = usersIdMap[userId] if userId in usersIdMap else {}
            ret['event']['adminUsers'].append(user)

    if withUserEvents:
        retStats = _user_event.GetStats(ret['event']['_id'], withUserId = withUserId)
        ret['attendeesCount'] = retStats['attendeesCount']
        ret['attendeesWaitingCount'] = retStats['attendeesWaitingCount']
        ret['nonHostAttendeesWaitingCount'] = retStats['nonHostAttendeesWaitingCount']
        ret['userEvent'] = retStats['userEvent']

    return ret

def Save(event: dict):
    event = _mongo_db_crud.CleanId(event)
    if '_id' not in event:
        event['uName'] = lodash.CreateUName(event['title'])
        if 'weeklyEventId' in event and len(event['weeklyEventId']) > 0 and 'weeklyEventUName' not in event:
            weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(event['weeklyEventId'])})['item']
            if weeklyEvent is not None:
                event['weeklyEventUName'] = weeklyEvent['uName']
    else:
        # Do not allow changing some fields.
        eventExisting = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(event['_id'])})['item']
        if eventExisting:
            event['hostGroupSizeDefault'] = eventExisting['hostGroupSizeDefault']
            event['priceUSD'] = eventExisting['priceUSD']
    if 'timezone' not in event or event['timezone'] == '':
        event['timezone'] = date_time.GetTimezoneFromLngLat(event['location']['coordinates'])
    payInfo = _event_payment.GetPayInfo(event['priceUSD'], event['hostGroupSizeDefault'])
    event['hostMoneyPerPersonUSD'] = payInfo['eventFunds']
    return _mongo_db_crud.Save('event', event)

def Remove(eventId: str):
    mongo_db.delete_many('userEvent', { 'eventId': eventId })
    return _mongo_db_crud.RemoveById('event', eventId)

def GetEventWithWeekly(eventId: str):
    ret = { "valid": 1, "message": "", 'weeklyEvent': {}, }
    ret['event'] = mongo_db.find_one('event', { "_id": mongo_db.to_object_id(eventId) })['item']
    if ret['event'] is not None:
        if 'weeklyEventId' in ret['event'] and len(ret['event']['weeklyEventId']) > 0:
            ret['weeklyEvent'] = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(ret['event']['weeklyEventId'])})['item']
            # eventStart = date_time.from_string(ret['event']['start'])
            # retNext = GetNextEventFromWeekly(ret['event']['weeklyEventId'], now = eventStart, weeklyEvent = ret['weeklyEvent'])
            # ret['nextEvent'] = retNext['event']
    return ret

def GetNextEventFromWeekly(weeklyEventId: str, minHoursBeforeRsvpDeadline: int = 0, now = None, autoCreate: int = 1,
    weeklyEvent: dict = None):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 0, 'message': '', 'event': {} }
    if weeklyEvent is None:
        weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    ret['weeklyEvent'] = weeklyEvent
    retNext = GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline, now)
    event = {
        'weeklyEventId': weeklyEventId,
        'weeklyEventUName': weeklyEvent['uName'],
        'start': retNext['nextStart'],
        'neighborhoodUName': weeklyEvent['neighborhoodUName'],
    }
    eventFind = mongo_db.find_one('event', event)['item']
    if eventFind:
        ret['event'] = eventFind
    elif not eventFind and autoCreate and not weeklyEvent['archived']:
        event['end'] = retNext['nextEnd']
        ret['event'] = _mongo_db_crud.Save('event', event)['event']
    return ret

def GetNextEvents(weeklyEventId: str, minHoursBeforeRsvpDeadline: int = 0, now = None, autoCreate: int = 1):
    ret = { 'valid': 1, 'message': '', 'thisWeekEvent': {}, 'nextWeekEvent': {}, 'rsvpDeadlinePassed': 0, }
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    retNext = GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline, now)
    ret['rsvpDeadlinePassed'] = retNext['rsvpDeadlinePassed']
    event = {
        'weeklyEventId': weeklyEventId,
        'weeklyEventUName': weeklyEvent['uName'],
        'start': retNext['thisWeekStart'],
        'neighborhoodUName': weeklyEvent['neighborhoodUName'],
    }
    eventFind = mongo_db.find_one('event', event)['item']
    if not eventFind and autoCreate and not weeklyEvent['archived']:
        event['end'] = retNext['thisWeekEnd']
        eventFind = _mongo_db_crud.Save('event', event)['event']
    if eventFind:
        ret['thisWeekEvent'] = eventFind
    if retNext['nextStart']:
        eventNext = {
            'weeklyEventId': weeklyEventId,
            'weeklyEventUName': weeklyEvent['uName'],
            'start': retNext['nextStart'],
            'neighborhoodUName': weeklyEvent['neighborhoodUName'],
        }
        eventNextFind = mongo_db.find_one('event', eventNext)['item']
        if not eventNextFind and autoCreate and not weeklyEvent['archived']:
            eventNext['end'] = retNext['nextEnd']
            eventNextFind = _mongo_db_crud.Save('event', eventNext)['event']
        if eventNextFind:
            ret['nextWeekEvent'] = eventNextFind
    return ret

def GetMostRecentPastEvent(weeklyEventId: str, now = None):
    ret = { 'valid': 1, 'message': '', 'event': {}, }
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    retNext = GetNextEventStart(weeklyEvent, now = now, minHoursBeforeRsvpDeadline = 0)
    pastStart = date_time.from_string(retNext['thisWeekStart']) - datetime.timedelta(days = 7)
    pastStart = date_time.string(pastStart)
    event = {
        'weeklyEventId': weeklyEventId,
        'start': pastStart,
    }
    ret['event'] = mongo_db.find_one('event', event)['item']
    if ret['event'] is None:
        ret['event'] = {}
    return ret

def GetNextEventStart(weeklyEvent: dict, minHoursBeforeRsvpDeadline: int = 0, now = None):
    ret = { 'valid': 1, 'message': '', 'nextStart': '', 'rsvpDeadlinePassed': 0, 'thisWeekStart': '',
        'nextEnd': '', 'thisWeekEnd': '', }
    now = now if now is not None else date_time.now()
    now = date_time.ToTimezone(now, weeklyEvent['timezone'])

    hour = int(weeklyEvent['startTime'][0:2])
    minute = int(weeklyEvent['startTime'][3:5])
    thisWeek = date_time.create(now.year, now.month, now.day, hour, minute, tz = weeklyEvent['timezone'])
    # Add difference between weekdays.
    thisWeek += datetime.timedelta(days=(weeklyEvent['dayOfWeek'] - now.weekday()))
    if thisWeek < now:
        thisWeek += datetime.timedelta(days = 7)
    thisWeek = date_time.toUTC(thisWeek)
    ret['thisWeekStart'] = date_time.string(thisWeek)
    hourEnd = int(weeklyEvent['endTime'][0:2])
    minuteEnd = int(weeklyEvent['endTime'][3:5])
    durationHours = hourEnd - hour
    if durationHours < 0:
        durationHours += 24
    durationMinutes = minuteEnd - minute
    duration = durationHours * 60 + durationMinutes
    thisWeekEnd = thisWeek + datetime.timedelta(minutes = duration)
    ret['thisWeekEnd'] = date_time.string(thisWeekEnd)

    hoursBuffer = minHoursBeforeRsvpDeadline + weeklyEvent['rsvpDeadlineHours']
    diffHours = date_time.diff(thisWeek, now, 'hours')
    if diffHours < weeklyEvent['rsvpDeadlineHours']:
        ret['rsvpDeadlinePassed'] = 1
    if (diffHours >= hoursBuffer):
        ret['nextStart'] = date_time.string(thisWeek)
        ret['nextEnd'] = date_time.string(thisWeekEnd)
        return ret
    nextWeek = thisWeek + datetime.timedelta(days = 7)
    ret['nextStart'] = date_time.string(nextWeek)
    nextWeekEnd = thisWeekEnd + datetime.timedelta(days = 7)
    ret['nextEnd'] = date_time.string(nextWeekEnd)
    return ret

def GetUsersAttending(daysPast: int = 7, weeklyEventIds = None, now = None,
    minDateString: str = '', maxDateString: str = '', withFreePaidStats: bool = False, limit: int = 100000,
    weeklyEventsById = {}):
    ret = { 'valid': 1, 'message': '', 'eventsCount': 0, 'uniqueUsersCount': 0, 'eventInfos': [], 
        'totalEventUsersCount': 0, 'freeEventsCount': 0, 'paidEventsCount': 0,
        'totalPaidEventUsersCount': 0, 'totalFreeEventUsersCount': 0, 'totalCutUSD': 0, }
    now = now if now is not None else date_time.now()
    if weeklyEventIds is not None:
        if len(weeklyEventIds) == 0:
            return ret
    if minDateString == '':
        minDateString = date_time.string(now - datetime.timedelta(days=daysPast))
    query = { 'start': { '$gte': minDateString } }
    if maxDateString != '':
        query['start']['$lte'] = maxDateString
    if weeklyEventIds is not None and len(weeklyEventIds) > 0:
        query['weeklyEventId'] = { '$in': weeklyEventIds }
    events = mongo_db.find('event', query)['items']
    ret['eventsCount'] = len(events)
    eventInfosMap = {}
    if len(events) > 0:
        eventIds = []
        for index, event in enumerate(events):
            eventIds.append(event['_id'])
            weeklyEventUName = weeklyEventsById[event['weeklyEventId']]['uName'] if event['weeklyEventId'] in weeklyEventsById else ''
            ret['eventInfos'].append({ 'id': event['_id'], 'start': event['start'], 'attendeeCount': 0,
                'firstEventAttendeeCount': 0,
                'weeklyEventId': event['weeklyEventId'], 'weeklyEventUName': weeklyEventUName, })
            eventInfosMap[event['_id']] = index
        query = { 'eventId': { '$in': eventIds }, 'attendeeCount': { '$gte': 1 } }
        userIds = mongo_db.findDistinct('userEvent', 'userId', query)['values']
        ret['uniqueUsersCount'] = len(userIds)
        if withFreePaidStats:
            fields = { 'creditsPriceUSD': 1, 'eventId': 1, 'userId': 1, 'attendeeCount': 1, 'createdAt': 1, }
            userEvents = mongo_db.find('userEvent', query, fields = fields, limit = limit)['items']
            ret['totalEventUsersCount'] = len(userEvents)
            ret['freeEventsCount'] = 0
            ret['paidEventsCount'] = 0
            ret['totalFreeEventUsersCount'] = 0
            ret['totalPaidEventUsersCount'] = 0
            ret['totalCutUSD'] = 0
            freeEventsMap = {}
            paidEventsMap = {}
            for userEvent in userEvents:
                ret['eventInfos'][eventInfosMap[userEvent['eventId']]]['attendeeCount'] += userEvent['attendeeCount']
                # See if this user has attended any events before this.
                query = { 'eventId': userEvent['eventId'], 'userId': userEvent['userId'],
                    'createdAt': { '$lt': userEvent['createdAt'] } }
                userEventBefore = mongo_db.find_one('userEvent', query)['item']
                if userEventBefore is None:
                    ret['eventInfos'][eventInfosMap[userEvent['eventId']]]['firstEventAttendeeCount'] += 1

                if userEvent['creditsPriceUSD'] == 0:
                    ret['totalFreeEventUsersCount'] += 1
                    if userEvent['eventId'] not in freeEventsMap:
                        freeEventsMap[userEvent['eventId']] = 1
                        ret['freeEventsCount'] += 1
                else:
                    ret['totalPaidEventUsersCount'] += 1
                    # Assume fixed $1 per paid event.
                    ret['totalCutUSD'] += 1
                    if userEvent['eventId'] not in paidEventsMap:
                        paidEventsMap[userEvent['eventId']] = 1
                        ret['paidEventsCount'] += 1
    return ret

# def GetByIds(ids: list = [], weeklyEventFields = None):
#     weeklyEventFields = weeklyEventFields if weeklyEventFields is not None else \
#         { '_id': 1, 'uName': 1, 'type': 1, 'title': 1, 'priceUSD': 1, }
#     ret = { 'valid': 1, 'message': '', 'events': [] }
#     objectIds = []
#     for eventId in ids:
#         objectIds.append(mongo_db.to_object_id(eventId))
#     events = mongo_db.find('event', { '_id': { '$in': objectIds } })['items']
#     weeklyEventIds = []
#     objectIds = []
#     indicesMap = {}
#     for index, event in enumerate(events):
#         if event['weeklyEventId'] not in weeklyEventIds:
#             weeklyEventIds.append(event['weeklyEventId'])
#             objectIds.append(mongo_db.to_object_id(event['weeklyEventId']))
#             if event['weeklyEventId'] not in indicesMap:
#                 indicesMap[event['weeklyEventId']] = []
#             indicesMap[event['weeklyEventId']].append(index)
#     fields = weeklyEventFields
#     weeklyEvents = mongo_db.find('weeklyEvent', { '_id': { '$in': objectIds } }, fields = fields)['items']
#     for weeklyEvent in weeklyEvents:
#         events[indicesMap[weeklyEvent['_id']]]['weeklyEvent'] = weeklyEvent
#     ret['events'] = events
#     return ret
