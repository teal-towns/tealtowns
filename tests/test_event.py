import date_time
from event import event as _event
import mongo_db
import mongo_mock as _mongo_mock
from stubs import stubs_data as _stubs_data

def test_GetNextEventStart():
    # Event Sunday 17:00
    weeklyEvent = {
        "dayOfWeek": 6,
        "startTime": '17:00',
        "endTime": '18:00',
        "timezone": "America/Los_Angeles",
        "rsvpDeadlineHours": 72,
    }
    minHoursBeforeRsvpDeadline = 24
    # Now is Thursday morning.
    now = date_time.from_string('2024-03-21T09:11:00-07:00')
    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 24, now = now)['nextStart']
    # assert start == '2024-03-31T17:00:00-07:00'
    assert start == '2024-04-01T00:00:00+00:00'

    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 2, now = now)['nextStart']
    assert start == '2024-03-25T00:00:00+00:00'

    # Now is Wednesday morning.
    now = date_time.from_string('2024-03-20T09:11:00-07:00')
    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 24, now = now)['nextStart']
    assert start == '2024-03-25T00:00:00+00:00'

    # Now is Sunday morning.
    now = date_time.from_string('2024-03-24T09:11:00-07:00')
    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 24, now = now)['nextStart']
    assert start == '2024-04-01T00:00:00+00:00'

    # Now is Monday morning.
    now = date_time.from_string('2024-03-25T09:11:00-07:00')
    start = _event.GetNextEventStart(weeklyEvent, minHoursBeforeRsvpDeadline = 24, now = now)['nextStart']
    assert start == '2024-04-01T00:00:00+00:00'

def test_GetNextEvents():
    _mongo_mock.InitAllCollections()
    weeklyEvent = {
        'startTime': '16:00',
        'endTime': '18:00',
        'dayOfWeek': 5,
        'rsvpDeadlineHours': 0,
        'timezone': 'America/Los_Angeles',
    }
    weeklyEvents = _stubs_data.CreateBulk(objs = [weeklyEvent], collectionName = 'weeklyEvent')
    weeklyEvent = weeklyEvents[0]
    now = date_time.from_string('2024-05-19T17:00:00-07:00')
    retEvents = _event.GetNextEvents(weeklyEvent['_id'], now = now)
    assert retEvents['thisWeekEvent']['start'] == '2024-05-25T23:00:00+00:00'
    assert retEvents['nextWeekEvent']['start'] == '2024-05-25T23:00:00+00:00'
    _mongo_mock.CleanUp()

def test_GetUsersAttending():
    _mongo_mock.InitAllCollections()
    users = _stubs_data.CreateBulk(count = 10, collectionName = 'user')

    events = [
        { 'start': '2024-03-01T17:00:00+00:00' },
        { 'start': '2024-03-03T17:00:00+00:00' },
        { 'start': '2024-03-05T17:00:00+00:00' },
        { 'start': '2024-03-07T17:00:00+00:00' },
        { 'start': '2024-03-09T17:00:00+00:00' },
    ]
    events = _stubs_data.CreateBulk(objs = events, collectionName = 'event')

    # Now is 1 day after the last event, meaning 4 events are within a week (event 0 is NOT)
    now = date_time.from_string('2024-03-10T17:00:00+00:00')

    # 0 since only attendee > 0 is for event 0, which is too far in the past.
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[0]['_id'], 'attendeeCount': 3, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'eventId': events[1]['_id'], },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], 'eventId': events[2]['_id'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, collectionName = 'userEvent')
    ret = _event.GetUsersAttending(now = now)
    assert ret['eventsCount'] == 4
    assert ret['uniqueUsersCount'] == 0
    mongo_db.delete_many('userEvent', {})

    # All 3
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[1]['_id'], 'attendeeCount': 1, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'eventId': events[1]['_id'], 'attendeeCount': 2, },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], 'eventId': events[2]['_id'], 'attendeeCount': 3, },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, collectionName = 'userEvent')
    ret = _event.GetUsersAttending(now = now)
    assert ret['eventsCount'] == 4
    assert ret['uniqueUsersCount'] == 3
    mongo_db.delete_many('userEvent', {})

    # 0 since filter by weekly event id
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[1]['_id'], 'attendeeCount': 1, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'eventId': events[1]['_id'], 'attendeeCount': 2, },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], 'eventId': events[2]['_id'], 'attendeeCount': 3, },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, collectionName = 'userEvent')
    ret = _event.GetUsersAttending(weeklyEventIds = ['badid'], now = now)
    assert ret['eventsCount'] == 0
    assert ret['uniqueUsersCount'] == 0
    mongo_db.delete_many('userEvent', {})

    # Only 1 since same user 3 times
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[1]['_id'], 'attendeeCount': 1, },
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[2]['_id'], 'attendeeCount': 2, },
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[3]['_id'], 'attendeeCount': 3, },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, collectionName = 'userEvent')
    ret = _event.GetUsersAttending(now = now)
    assert ret['eventsCount'] == 4
    assert ret['uniqueUsersCount'] == 1
    mongo_db.delete_many('userEvent', {})

    # 2 since only 2 unique users
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[1]['_id'], 'attendeeCount': 1, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'eventId': events[2]['_id'], 'attendeeCount': 2, },
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[3]['_id'], 'attendeeCount': 3, },
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[4]['_id'], 'attendeeCount': 1, },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, collectionName = 'userEvent')
    ret = _event.GetUsersAttending(now = now)
    assert ret['eventsCount'] == 4
    assert ret['uniqueUsersCount'] == 2
    mongo_db.delete_many('userEvent', {})

    _mongo_mock.CleanUp()
