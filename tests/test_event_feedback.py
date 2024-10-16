import date_time
import mongo_db
import mongo_mock as _mongo_mock
from common import mongo_db_crud as _mongo_db_crud
from event import event_feedback as _event_feedback
from stubs import stubs_data as _stubs_data

def test_EventFeedbackVotes():
    _mongo_mock.InitAllCollections()
    eventFeedback = {
        'eventId': 'event1',
        'feedbackVotes': [],
        'positiveVotes': [],
        'notificationSent': 0,
    }
    ret = _mongo_db_crud.Save('eventFeedback', eventFeedback)
    assert ret['eventFeedback']['eventId'] == eventFeedback['eventId']
    eventFeedback = ret['eventFeedback']

    # User 1 adds feedback vote
    feedbackVoteGreat = { 'userIds': [ 'user1' ], 'feedback': 'Great event' }
    ret = _event_feedback.AddFeedbackVote(eventFeedback['_id'], feedbackVoteGreat)
    feedbackVoteGreat = ret['feedbackVote']
    item = mongo_db.find_one('eventFeedback', {'_id': eventFeedback['_id']})['item']
    assert len(item['feedbackVotes']) == 1
    for feedbackVote in item['feedbackVotes']:
        if feedbackVote['id'] == feedbackVoteGreat['id']:
            assert feedbackVote['userIds'] == [ 'user1' ]
            assert feedbackVote['feedback'] == feedbackVoteGreat['feedback']

    # User 2 votes for same feedback
    _event_feedback.AddUserFeedbackVote(eventFeedback['_id'], 'user2', feedbackVoteGreat['id'])
    item = mongo_db.find_one('eventFeedback', {'_id': eventFeedback['_id']})['item']
    assert len(item['feedbackVotes']) == 1
    for feedbackVote in item['feedbackVotes']:
        if feedbackVote['id'] == feedbackVoteGreat['id']:
            assert feedbackVote['userIds'] == [ 'user1', 'user2' ]
            assert feedbackVote['feedback'] == feedbackVoteGreat['feedback']
    
    # User 1 tries to duplicate vote (blocked).
    _event_feedback.AddUserFeedbackVote(eventFeedback['_id'], 'user1', feedbackVoteGreat['id'])
    item = mongo_db.find_one('eventFeedback', {'_id': eventFeedback['_id']})['item']
    assert len(item['feedbackVotes']) == 1
    for feedbackVote in item['feedbackVotes']:
        if feedbackVote['id'] == feedbackVoteGreat['id']:
            assert feedbackVote['userIds'] == [ 'user1', 'user2' ]
            assert feedbackVote['feedback'] == feedbackVoteGreat['feedback']
    
    # User 1 removes vote from feedback
    _event_feedback.RemoveFeedbackUserVote(eventFeedback['_id'], feedbackVoteGreat['id'], 'user1')
    item = mongo_db.find_one('eventFeedback', {'_id': eventFeedback['_id']})['item']
    assert len(item['feedbackVotes']) == 1
    for feedbackVote in item['feedbackVotes']:
        if feedbackVote['id'] == feedbackVoteGreat['id']:
            assert feedbackVote['userIds'] == [ 'user2' ]
            assert feedbackVote['feedback'] == feedbackVoteGreat['feedback']

    _mongo_mock.CleanUp()

def test_CheckAndCreateForEndingEvents():
    _mongo_mock.InitAllCollections()
    users = _stubs_data.CreateBulk(count = 2, collectionName = 'user')
    events = [
        { 'start': '2024-03-01T17:00:00-07:00', 'end': '2024-03-01T18:00:00-07:00' },
        { 'start': '2024-03-01T15:00:00-07:00', 'end': '2024-03-01T17:55:00-07:00' },
        { 'start': '2024-03-01T17:00:00-07:00', 'end': '2024-03-01T17:45:00-07:00' },
        { 'start': '2024-03-07T17:00:00-07:00', 'end': '2024-03-07T18:00:00-07:00' },
        { 'start': '2024-03-09T17:00:00-07:00', 'end': '2024-03-09T18:00:00-07:00' },
    ]
    events = _stubs_data.CreateBulk(objs = events, collectionName = 'event')
    # User 0 went to events 0, 3, 4 (signed up for 1 but did not get a spot).
    # User 1 went to events 0, 1
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[0]['_id'], 'attendeeCount': 3, 'eventEnd': events[0]['end'], },
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[1]['_id'], 'attendeeCount': 0, 'eventEnd': events[1]['end'], },
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[3]['_id'], 'attendeeCount': 1, 'eventEnd': events[3]['end'], },
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'eventId': events[4]['_id'], 'attendeeCount': 2, 'eventEnd': events[4]['end'], },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'eventId': events[0]['_id'], 'attendeeCount': 1, 'eventEnd': events[0]['end'], },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'eventId': events[1]['_id'], 'attendeeCount': 2, 'eventEnd': events[1]['end'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, collectionName = 'userEvent')

    # Near end of events 0 and 1, and just after event 2, so all 3 should have feedback created.
    now = date_time.from_string('2024-03-01T17:50:00-07:00')
    ret = _event_feedback.CheckAndCreateForEndingEvents(now = now, notify = 1)
    assert len(ret['newFeedbackEventIds']) == 3
    for eventId in ret['newFeedbackEventIds']:
        assert eventId in [events[0]['_id'], events[1]['_id'], events[2]['_id']]
        if eventId == events[0]['_id']:
            assert ret['notifyByEvent'][eventId]['notifyUserIds']['sms'] == [ users[0]['_id'], users[1]['_id'] ]
        elif eventId == events[1]['_id']:
            assert ret['notifyByEvent'][eventId]['notifyUserIds']['sms'] == [ users[1]['_id'] ]
        elif eventId == events[2]['_id']:
            assert ret['notifyByEvent'][eventId]['notifyUserIds']['sms'] == []
    
    # Should NOT send twice.
    now = date_time.from_string('2024-03-01T17:55:00-07:00')
    ret = _event_feedback.CheckAndCreateForEndingEvents(now = now, notify = 1)
    assert len(ret['newFeedbackEventIds']) == 0

    _mongo_mock.CleanUp()