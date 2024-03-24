import datetime

from common import mongo_db_crud as _mongo_db_crud
import date_time
import mongo_db

def GetNextEventFromWeekly(weeklyEventId: str, minHoursBeforeRsvpDeadline: int = 24, now = None, autoCreate: int = 1):
    now = now if now else date_time.now()
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

def GetNextEventStart(weeklyEvent: dict, minHoursBeforeRsvpDeadline: int = 24, now = None):
    ret = { 'valid': 1, 'message': '', 'nextStart': '', 'rsvpDeadlinePassed': 0, 'thisWeekStart': '', }
    now = now if now else date_time.now()
    now = date_time.ToTimezone(now, weeklyEvent['timezone'])

    hour = int(weeklyEvent['startTime'][0:2])
    minute = int(weeklyEvent['startTime'][3:5])
    thisWeek = datetime.datetime(now.year, now.month, now.day, hour, minute)
    thisWeek = date_time.ToTimezone(thisWeek, weeklyEvent['timezone'])
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
