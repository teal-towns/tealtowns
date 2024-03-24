import date_time
from event import event as _event

def test_GetNextEventStart():
    # Event Sunday 17:00
    weeklyEvent = {
        "dayOfWeek": 6,
        "startTime": '17:00',
        "timezone": "America/Los_Angeles",
        "rsvpDeadlineHours": 72,
    }
    minHoursBeforeRsvpDeadline = 24
    # Now is Thursday morning.
    now = date_time.from_string('2024-03-21T09:11:00-07:00')
    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 24, now = now)['nextStart']
    assert start == '2024-03-31T17:00:00-07:00'

    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 2, now = now)['nextStart']
    assert start == '2024-03-24T17:00:00-07:00'

    # Now is Wednesday morning.
    now = date_time.from_string('2024-03-20T09:11:00-07:00')
    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 24, now = now)['nextStart']
    assert start == '2024-03-24T17:00:00-07:00'

    # Now is Sunday morning.
    now = date_time.from_string('2024-03-24T09:11:00-07:00')
    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 24, now = now)['nextStart']
    assert start == '2024-03-31T17:00:00-07:00'

    # Now is Monday morning.
    now = date_time.from_string('2024-03-25T09:11:00-07:00')
    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 24, now = now)['nextStart']
    assert start == '2024-03-31T17:00:00-07:00'
