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
        fields = { "firstName": 1, "lastName": 1, "email": 1, }
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

def GetNextEventFromWeekly(weeklyEventId: str, minHoursBeforeRsvpDeadline: int = 24, now = None, autoCreate: int = 1):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 0, 'message': '', 'event': {} }
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    ret['weeklyEvent'] = weeklyEvent
    nextStart = GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline, now)['nextStart']
    event = {
        'weeklyEventId': weeklyEventId,
        'start': nextStart,
    }
    eventFind = mongo_db.find_one('event', event)['item']
    if eventFind:
        ret['event'] = eventFind
    elif not eventFind and autoCreate:
        ret['event'] = _mongo_db_crud.Save('event', event)['event']
    return ret

def GetNextEvents(weeklyEventId: str, minHoursBeforeRsvpDeadline: int = 0, now = None, autoCreate: int = 1):
    ret = { 'valid': 1, 'message': '', 'thisWeekEvent': {}, 'nextWeekEvent': {}, 'rsvpDeadlinePassed': 0, }
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    retNext = GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline, now)
    ret['rsvpDeadlinePassed'] = retNext['rsvpDeadlinePassed']
    event = {
        'weeklyEventId': weeklyEventId,
        'start': retNext['thisWeekStart'],
    }
    eventFind = mongo_db.find_one('event', event)['item']
    if not eventFind and autoCreate:
        eventFind = _mongo_db_crud.Save('event', event)['event']
    if eventFind:
        ret['thisWeekEvent'] = eventFind
    if retNext['nextStart']:
        eventNext = {
            'weeklyEventId': weeklyEventId,
            'start': retNext['nextStart'],
        }
        eventNextFind = mongo_db.find_one('event', eventNext)['item']
        if not eventNextFind and autoCreate:
            eventNextFind = _mongo_db_crud.Save('event', eventNext)['event']
        if eventNextFind:
            ret['nextWeekEvent'] = eventNextFind
    return ret

def GetNextEventStart(weeklyEvent: dict, minHoursBeforeRsvpDeadline: int = 24, now = None):
    ret = { 'valid': 1, 'message': '', 'nextStart': '', 'rsvpDeadlinePassed': 0, 'thisWeekStart': '', }
    now = now if now is not None else date_time.now()
    now = date_time.ToTimezone(now, weeklyEvent['timezone'])

    hour = int(weeklyEvent['startTime'][0:2])
    minute = int(weeklyEvent['startTime'][3:5])
    thisWeek = date_time.create(now.year, now.month, now.day, hour, minute, tz = weeklyEvent['timezone'])
    # Add difference between weekdays.
    thisWeek += datetime.timedelta(days=(weeklyEvent['dayOfWeek'] - now.weekday()))
    ret['thisWeekStart'] = date_time.string(thisWeek)

    hoursBuffer = minHoursBeforeRsvpDeadline + weeklyEvent['rsvpDeadlineHours']
    diffHours = date_time.diff(thisWeek, now, 'hours')
    if diffHours < weeklyEvent['rsvpDeadlineHours']:
        ret['rsvpDeadlinePassed'] = 1
    if (diffHours >= hoursBuffer):
        ret['nextStart'] = date_time.string(thisWeek)
        return ret
    nextWeek = thisWeek + datetime.timedelta(days = 7)
    ret['nextStart'] = date_time.string(nextWeek)
    return ret

def GetUsersAttending(daysPast: int = 7, weeklyEventIds: list = [], now = None):
    ret = { 'valid': 1, 'message': '', 'eventsCount': 0, 'usersCount': 0, }
    now = now if now is not None else date_time.now()
    minDate = date_time.string(now - datetime.timedelta(days=daysPast))
    query = { 'start': { '$gte': minDate } }
    if len(weeklyEventIds) > 0:
        query['weeklyEventId'] = { '$in': weeklyEventIds }
    events = mongo_db.find('event', query)['items']
    ret['eventsCount'] = len(events)
    if len(events) > 0:
        eventIds = []
        for event in events:
            eventIds.append(event['_id'])
        query = { 'eventId': { '$in': eventIds }, 'attendeeCount': { '$gte': 1 } }
        userIds = mongo_db.findDistinct('userEvent', 'userId', query)['values']
        ret['usersCount'] = len(userIds)
    return ret
