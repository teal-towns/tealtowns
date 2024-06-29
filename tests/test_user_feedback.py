import date_time
import mongo_mock as _mongo_mock
import mongo_db
from common import mongo_db_crud as _mongo_db_crud
from event import user_feedback as _user_feedback
from stubs import stubs_data as _stubs_data

def test_GuessContactType():
    ret = _user_feedback.GuessContactType('1-555-123-4567')
    assert ret == 'phone'

    ret = _user_feedback.GuessContactType('15551234567')
    assert ret == 'phone'

    ret = _user_feedback.GuessContactType('2rHv0@example.com')
    assert ret == 'email'

    ret = _user_feedback.GuessContactType('test')
    assert ret == ''

def test_Save():
    _mongo_mock.InitAllCollections()
    users = _stubs_data.CreateBulk(count = 1, collectionName = 'user')
    weeklyEvents = _stubs_data.CreateBulk(count = 1, collectionName = 'weeklyEvent',)
    events = [
        { 'weeklyEventId': weeklyEvents[0]['_id'], },
    ]
    events = _stubs_data.CreateBulk(objs = events, collectionName = 'event')

    userFeedback = {
        'userId': users[0]['_id'],
        'forType': 'event',
        'forId': events[0]['_id'],
        'willJoinNextWeek': 'yes',
        'attended': 'yes',
        'stars': 3,
        'willInvite': '',
        'invites': ['Joe S', '1-555-123-4567', 'yes@email.com', '1.382.385.2385'],
    }
    ret = _user_feedback.Save(userFeedback)
    assert ret['smsAttemptCount'] == 2
    assert ret['emailAttemptCount'] == 1

    _mongo_mock.CleanUp()

def test_CheckAskForFeedback():
    _mongo_mock.InitAllCollections()

    users = _stubs_data.CreateBulk(count = 2, collectionName = 'user')
    events = [
        { 'start': '2024-03-01T17:00:00-07:00', 'end': '2024-03-01T18:00:00-07:00' },
        { 'start': '2024-03-03T17:00:00-07:00', 'end': '2024-03-03T18:00:00-07:00' },
        { 'start': '2024-03-05T17:00:00-07:00', 'end': '2024-03-05T18:00:00-07:00' },
        { 'start': '2024-03-07T17:00:00-07:00', 'end': '2024-03-07T18:00:00-07:00' },
        { 'start': '2024-03-09T17:00:00-07:00', 'end': '2024-03-09T18:00:00-07:00' },
    ]
    events = _stubs_data.CreateBulk(objs = events, collectionName = 'event')
    # User 0 went to events 0, 3, 4 (signed up for 1 but did not get a spot).
    userEvents = [
        { 'userId': users[0]['_id'], 'eventId': events[0]['_id'], 'attendeeCount': 3, 'eventEnd': events[0]['end'], },
        { 'userId': users[0]['_id'], 'eventId': events[1]['_id'], 'attendeeCount': 0, 'eventEnd': events[1]['end'], },
        { 'userId': users[0]['_id'], 'eventId': events[3]['_id'], 'attendeeCount': 1, 'eventEnd': events[3]['end'], },
        { 'userId': users[0]['_id'], 'eventId': events[4]['_id'], 'attendeeCount': 2, 'eventEnd': events[4]['end'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, collectionName = 'userEvent')

    # Right before end of event 4.
    now = date_time.from_string('2024-03-09T17:55:00-07:00')
    ret = _user_feedback.CheckAskForFeedback(users[0]['_id'], eventId = events[4]['_id'], now = now)
    assert ret['missingFeedbackEventIds'] == [ events[4]['_id'] ]

    # Too far before end of event 4.
    now = date_time.from_string('2024-03-09T17:45:00-07:00')
    ret = _user_feedback.CheckAskForFeedback(users[0]['_id'], eventId = events[4]['_id'], now = now)
    assert ret['missingFeedbackEventIds'] == []

    # Distance in past does not matter if given a specific event.
    now = date_time.from_string('2024-03-25T17:55:00-07:00')
    ret = _user_feedback.CheckAskForFeedback(users[0]['_id'], eventId = events[0]['_id'], now = now)
    assert ret['missingFeedbackEventIds'] == [ events[0]['_id'] ]

    # Already gave feedback
    userFeedback = { 'userId': users[0]['_id'], 'forType': 'event', 'forId': events[3]['_id'],
        'attended': 'yes', 'stars': 4, 'willJoinNextWeek': 'yes', }
    ret = _mongo_db_crud.Save('userFeedback', userFeedback)
    now = date_time.from_string('2024-03-09T18:30:00-07:00')
    ret = _user_feedback.CheckAskForFeedback(users[0]['_id'], eventId = events[3]['_id'], now = now)
    assert ret['missingFeedbackEventIds'] == []

    # Without specific event id.
    # User 0 went to 0, 3, 4 and already gave feedback for 3, should just 0 and 4 left.
    # Right before end of event 4.
    now = date_time.from_string('2024-03-09T17:55:00-07:00')
    ret = _user_feedback.CheckAskForFeedback(users[0]['_id'], now = now)
    assert len(ret['missingFeedbackEventIds']) == 2
    for eventId in ret['missingFeedbackEventIds']:
        assert eventId in [ events[0]['_id'], events[4]['_id'] ]

    # Too far before end of event 4, so just 0
    now = date_time.from_string('2024-03-09T17:45:00-07:00')
    ret = _user_feedback.CheckAskForFeedback(users[0]['_id'], now = now)
    assert len(ret['missingFeedbackEventIds']) == 1
    for eventId in ret['missingFeedbackEventIds']:
        assert eventId in [ events[0]['_id'] ]

    # Too far in past
    now = date_time.from_string('2024-03-25T17:55:00-07:00')
    ret = _user_feedback.CheckAskForFeedback(users[0]['_id'], now = now)
    assert ret['missingFeedbackEventIds'] == []
    
    _mongo_mock.CleanUp()
