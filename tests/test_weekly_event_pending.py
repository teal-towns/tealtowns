import date_time
import lodash
import mongo_db
import mongo_mock as _mongo_mock
from event import weekly_event as _weekly_event
from stubs import stubs_data as _stubs_data

def test_WeeklyEventsPending():
    _mongo_mock.InitAllCollections()
    userDefault = { 'phoneNumberVerified': 1, }
    users = _stubs_data.CreateBulk(count = 10, collectionName = 'user', default = userDefault)
    neighborhoods = _stubs_data.CreateBulk(count = 3, collectionName = 'neighborhood')
    type = 'sharedMeal'
    hostGroupSizeDefault = 3
    weeklyEvents = [
        { 'neighborhoodUName' : neighborhoods[2]['uName'], 'type': type, 'dayOfWeek': 0, 'startTime': '17:30',
            'hostGroupSizeDefault': hostGroupSizeDefault },
        { 'neighborhoodUName' : neighborhoods[2]['uName'], 'type': type, 'dayOfWeek': 0, 'startTime': '19:30',
            'hostGroupSizeDefault': hostGroupSizeDefault },
        { 'neighborhoodUName' : neighborhoods[2]['uName'], 'type': type, 'dayOfWeek': 1, 'startTime': '17:30',
            'hostGroupSizeDefault': hostGroupSizeDefault },
        { 'neighborhoodUName' : neighborhoods[2]['uName'], 'type': type, 'dayOfWeek': 3, 'startTime': '17:30',
            'hostGroupSizeDefault': hostGroupSizeDefault },
        # Others that should NOT match.
        { 'neighborhoodUName' : neighborhoods[0]['uName'], 'type': 'type2', 'dayOfWeek': 0, 'startTime': '17:30',},
        { 'neighborhoodUName' : neighborhoods[1]['uName'], 'type': type, 'dayOfWeek': 0, 'startTime': '19:30',},
    ]
    weeklyEvents = _stubs_data.CreateBulk(weeklyEvents, collectionName = 'weeklyEvent')

    startTimes = ['17:30', '19:30']
    ret = _weekly_event.GetByTimes(startTimes, daysOfWeek = [0,1,2,3],
        neighborhoodUName = neighborhoods[2]['uName'], type = type)
    assert len(ret['weeklyEvents']) == 4
    assert ret['weeklyEvents'][0]['dayOfWeek'] == 0
    assert ret['weeklyEvents'][0]['startTime'] == '17:30'
    assert ret['weeklyEvents'][0]['pendingUsers'] == []
    assert ret['weeklyEvents'][1]['dayOfWeek'] == 0
    assert ret['weeklyEvents'][1]['startTime'] == '19:30'
    assert ret['weeklyEvents'][1]['pendingUsers'] == []
    assert ret['weeklyEvents'][2]['dayOfWeek'] == 1
    assert ret['weeklyEvents'][2]['startTime'] == '17:30'
    assert ret['weeklyEvents'][2]['pendingUsers'] == []
    assert ret['weeklyEvents'][3]['dayOfWeek'] == 3
    assert ret['weeklyEvents'][3]['startTime'] == '17:30'
    assert ret['weeklyEvents'][3]['pendingUsers'] == []

    weeklyEventDefault = { 'neighborhoodUName': neighborhoods[0]['uName'], 'type': type, 'title': 'Dinner',
        'hostGroupSizeDefault': hostGroupSizeDefault, 'adminUserIds': [],
        'priceUSD': 9 }

    # Save for existing (non pending) event.
    weeklyEventsNew = [
        # Existing (non pending) event.
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 0, 'startTime': '19:30', 'pendingUsers': [
            { 'userId': users[8]['_id'], 'attendeeCountAsk': 2, 'hostGroupSizeMax': 0, 'selfHostCount': 0 }
        ], 'neighborhoodUName': neighborhoods[2]['uName'] }),
    ]
    ret = _weekly_event.CheckAndSavePending(weeklyEventsNew, users[8]['_id'], startTimes, type = type,
        neighborhoodUName = neighborhoods[2]['uName'])
    assert len(ret['weeklyEventUNamesToJoin']) == 1

    # Save pending events for user 9 (not used later, but will affect sort order and indices).
    weeklyEventsNew = [
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 0, 'startTime': '19:30', 'pendingUsers': [
            { 'userId': users[9]['_id'], 'attendeeCountAsk': 1, 'hostGroupSizeMax': 0, 'selfHostCount': 0 }
        ] }),
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 3, 'startTime': '17:30', 'pendingUsers': [
            { 'userId': users[9]['_id'], 'attendeeCountAsk': 2, 'hostGroupSizeMax': 0, 'selfHostCount': 0 }
        ] }),
    ]
    ret = _weekly_event.CheckAndSavePending(weeklyEventsNew, users[9]['_id'], startTimes, type = type,
        neighborhoodUName = neighborhoods[0]['uName'])

    # Save pending events for user 0. 3 new.
    weeklyEventsNew = [
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 0, 'startTime': '17:30', 'pendingUsers': [
            { 'userId': users[0]['_id'], 'attendeeCountAsk': 1, 'hostGroupSizeMax': 0, 'selfHostCount': 0 }
        ] }),
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 1, 'startTime': '17:30', 'pendingUsers': [
            { 'userId': users[0]['_id'], 'attendeeCountAsk': 2, 'hostGroupSizeMax': 0, 'selfHostCount': 0 }
        ] }),
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 2, 'startTime': '19:30', 'pendingUsers': [
            { 'userId': users[0]['_id'], 'attendeeCountAsk': 0, 'hostGroupSizeMax': 0, 'selfHostCount': 1 }
        ] }),
    ]
    ret = _weekly_event.CheckAndSavePending(weeklyEventsNew, users[0]['_id'], startTimes, type = type,
        neighborhoodUName = neighborhoods[0]['uName'])
    assert len(ret['weeklyEventsCreated']) == 3
    assert len(ret['notifyUserIds']['sms']) == 0
    assert len(ret['notifyUserIds']['email']) == 0
    retGet = _weekly_event.GetByTimes(startTimes, neighborhoodUName = neighborhoods[0]['uName'], type = type)
    assert len(retGet['weeklyEvents']) == 5
    assert retGet['weeklyEvents'][0]['dayOfWeek'] == 0
    assert retGet['weeklyEvents'][0]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][0]['pendingUsers']) == 1
    assert retGet['weeklyEvents'][0]['pendingUsers'][0]['userId'] == users[0]['_id']
    assert retGet['weeklyEvents'][0]['pendingUsers'][0]['attendeeCountAsk'] == 1
    assert retGet['weeklyEvents'][1]['dayOfWeek'] == 0
    assert retGet['weeklyEvents'][1]['startTime'] == '19:30'
    assert len(retGet['weeklyEvents'][1]['pendingUsers']) == 1
    assert retGet['weeklyEvents'][2]['dayOfWeek'] == 1
    assert retGet['weeklyEvents'][2]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][2]['pendingUsers']) == 1
    assert retGet['weeklyEvents'][2]['pendingUsers'][0]['userId'] == users[0]['_id']
    assert retGet['weeklyEvents'][2]['pendingUsers'][0]['attendeeCountAsk'] == 2
    assert retGet['weeklyEvents'][3]['dayOfWeek'] == 2
    assert retGet['weeklyEvents'][3]['startTime'] == '19:30'
    assert len(retGet['weeklyEvents'][3]['pendingUsers']) == 1
    assert retGet['weeklyEvents'][3]['pendingUsers'][0]['userId'] == users[0]['_id']
    assert retGet['weeklyEvents'][3]['pendingUsers'][0]['attendeeCountAsk'] == 0
    assert retGet['weeklyEvents'][3]['pendingUsers'][0]['selfHostCount'] == 1
    assert retGet['weeklyEvents'][4]['dayOfWeek'] == 3
    assert retGet['weeklyEvents'][4]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][4]['pendingUsers']) == 1

    # Save pending events for user 1. 2 existing.
    weeklyEventsNew = [
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 0, 'startTime': '17:30', 'pendingUsers': [
            { 'userId': users[1]['_id'], 'attendeeCountAsk': 1, 'hostGroupSizeMax': 0, 'selfHostCount': 0 }
        ] }),
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 1, 'startTime': '17:30', 'pendingUsers': [
            { 'userId': users[1]['_id'], 'attendeeCountAsk': 1, 'hostGroupSizeMax': 0, 'selfHostCount': 0 }
        ] }),
    ]
    ret = _weekly_event.CheckAndSavePending(weeklyEventsNew, users[1]['_id'], startTimes, type = type,
        neighborhoodUName = neighborhoods[0]['uName'])
    assert len(ret['weeklyEventsCreated']) == 0
    assert len(ret['notifyUserIds']['sms']) == 0
    assert len(ret['notifyUserIds']['email']) == 0
    retGet = _weekly_event.GetByTimes(startTimes, neighborhoodUName = neighborhoods[0]['uName'], type = type)
    assert len(retGet['weeklyEvents']) == 5
    assert retGet['weeklyEvents'][0]['dayOfWeek'] == 0
    assert retGet['weeklyEvents'][0]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][0]['pendingUsers']) == 2
    assert retGet['weeklyEvents'][2]['dayOfWeek'] == 1
    assert retGet['weeklyEvents'][2]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][2]['pendingUsers']) == 2

    # Save pending events for user 2. 1 existing. Since host group size is 3, should have enough people BUT no hosts yet.
    weeklyEventsNew = [
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 1, 'startTime': '17:30', 'pendingUsers': [
            { 'userId': users[2]['_id'], 'attendeeCountAsk': 1, 'hostGroupSizeMax': 0, 'selfHostCount': 0 }
        ] }),
    ]
    ret = _weekly_event.CheckAndSavePending(weeklyEventsNew, users[2]['_id'], startTimes, type = type,
        neighborhoodUName = neighborhoods[0]['uName'])
    assert len(ret['weeklyEventsCreated']) == 0
    assert len(ret['notifyUserIds']['sms']) == 0
    assert len(ret['notifyUserIds']['email']) == 0
    retGet = _weekly_event.GetByTimes(startTimes, neighborhoodUName = neighborhoods[0]['uName'], type = type)
    assert len(retGet['weeklyEvents']) == 5
    assert retGet['weeklyEvents'][0]['dayOfWeek'] == 0
    assert retGet['weeklyEvents'][0]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][0]['pendingUsers']) == 2
    assert retGet['weeklyEvents'][2]['dayOfWeek'] == 1
    assert retGet['weeklyEvents'][2]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][2]['pendingUsers']) == 3
    assert len(retGet['weeklyEvents'][2]['adminUserIds']) == 0

    # Save pending events for user 3. 1 existing. Host, so should create event.
    weeklyEventsNew = [
        lodash.extend_object(weeklyEventDefault, { 'dayOfWeek': 1, 'startTime': '17:30', 'pendingUsers': [
            { 'userId': users[3]['_id'], 'attendeeCountAsk': 1, 'hostGroupSizeMax': 10, 'selfHostCount': 0 }
        ] }),
    ]
    ret = _weekly_event.CheckAndSavePending(weeklyEventsNew, users[3]['_id'], startTimes, type = type,
        neighborhoodUName = neighborhoods[0]['uName'])
    assert len(ret['weeklyEventsCreated']) == 0
    assert len(ret['notifyUserIds']['sms']) == 4
    assert len(ret['notifyUserIds']['email']) == 0
    retGet = _weekly_event.GetByTimes(startTimes, neighborhoodUName = neighborhoods[0]['uName'], type = type)
    assert len(retGet['weeklyEvents']) == 5
    assert retGet['weeklyEvents'][0]['dayOfWeek'] == 0
    assert retGet['weeklyEvents'][0]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][0]['pendingUsers']) == 2
    assert retGet['weeklyEvents'][2]['dayOfWeek'] == 1
    assert retGet['weeklyEvents'][2]['startTime'] == '17:30'
    assert len(retGet['weeklyEvents'][2]['pendingUsers']) == 0
    assert len(retGet['weeklyEvents'][2]['adminUserIds']) == 1
    # Only host should be admin.
    for adminUserId in retGet['weeklyEvents'][2]['adminUserIds']:
        assert adminUserId in [users[3]['_id']]

    _mongo_mock.CleanUp()
