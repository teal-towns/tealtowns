import lodash
import mongo_db
import mongo_mock as _mongo_mock
from stubs import stubs_data as _stubs_data
from neighborhood import user_neighborhood as _user_neighborhood
from user import user_interest as _user_interest
from user import user_availability as _user_availability

def test_CheckCommonInterestsAndTimesByUser():
    _mongo_mock.InitAllCollections()
    users = _stubs_data.CreateBulk(count = 6, collectionName = 'user')
    neighborhoods = _stubs_data.CreateBulk(count = 2, collectionName = 'neighborhood')
    userNeighborhoods = [
        { 'userId': users[0]['_id'], 'neighborhoodUName': neighborhoods[0]['uName'], },
        { 'userId': users[1]['_id'], 'neighborhoodUName': neighborhoods[0]['uName'], },
        { 'userId': users[2]['_id'], 'neighborhoodUName': neighborhoods[0]['uName'], },
        { 'userId': users[3]['_id'], 'neighborhoodUName': neighborhoods[1]['uName'], },
        { 'userId': users[4]['_id'], 'neighborhoodUName': neighborhoods[0]['uName'], },
        { 'userId': users[5]['_id'], 'neighborhoodUName': neighborhoods[0]['uName'], },
    ]
    for userNeighborhood in userNeighborhoods:
        userNeighborhood = lodash.extend_object({ 'status': 'default', 'motivations': [], }, userNeighborhood)
        _user_neighborhood.Save(userNeighborhood)

    weeklyEvents = [
        { 'neighborhoodUName': neighborhoods[0]['uName'], 'dayOfWeek': 0, 'startTime': '16:00', 'endTime': '18:00',
            'tags': ['soccer'], },
        { 'neighborhoodUName': neighborhoods[0]['uName'], 'dayOfWeek': 0, 'startTime': '09:00', 'endTime': '10:30',
            'tags': ['soccer'], },
    ]
    weeklyEvents = _stubs_data.CreateBulk(weeklyEvents, collectionName = 'weeklyEvent')

    userInterests = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'interests': [ 'soccer',], },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'interests': [ 'baseball',], },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], 'interests': [ 'soccer',], },
        { 'userId': users[3]['_id'], 'username': users[3]['username'], 'interests': [ 'soccer',], },
        { 'userId': users[4]['_id'], 'username': users[4]['username'], 'interests': [ 'soccer',], },
        { 'userId': users[5]['_id'], 'username': users[5]['username'], 'interests': [ 'soccer',], },
    ]
    userInterests = _stubs_data.CreateBulk(userInterests, collectionName = 'userInterest')

    # No availability yet.
    userInterest =  { '_id': userInterests[0]['_id'], 'userId': users[0]['_id'], 'username': users[0]['username'],
        'interests': [ 'fitness', 'soccer', ] }
    retSave = _user_interest.Save(userInterest)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 0
    assert len(retSave['notifyUserIds']['sms']) == 0
    assert len(retSave['notifyUserIds']['email']) == 0

    # Match to weekly event 0; should be invited.
    userAvailability = { 'userId': users[0]['_id'], 'username': users[0]['username'], 'availableTimesByDay': [
        { 'dayOfWeek': 0, 'times': [ { 'start': '16:00', 'end': '17:00', }], },
    ]}
    retSave = _user_availability.Save(userAvailability)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 1
    assert retSave['weeklyEventsInvited'][0]['_id'] == weeklyEvents[0]['_id']
    notifyUserIds = retSave['notifyUserIds']['sms'] + retSave['notifyUserIds']['email']
    assert len(notifyUserIds) == 1
    assert notifyUserIds[0] == users[0]['_id']

    # Different interests, so no match.
    userAvailability = { 'userId': users[1]['_id'], 'username': users[1]['username'], 'availableTimesByDay': [
        { 'dayOfWeek': 0, 'times': [ { 'start': '16:00', 'end': '17:00', }], },
    ]}
    retSave = _user_availability.Save(userAvailability)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 0
    assert len(retSave['notifyUserIds']['sms']) == 0
    assert len(retSave['notifyUserIds']['email']) == 0

    # 1st user with a match, but need 3, so nothing yet.
    userAvailability = { 'userId': users[2]['_id'], 'username': users[2]['username'], 'availableTimesByDay': [
        { 'dayOfWeek': 1, 'times': [ { 'start': '16:00', 'end': '17:00', }], },
    ]}
    retSave = _user_availability.Save(userAvailability)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 0
    assert len(retSave['notifyUserIds']['sms']) == 0
    assert len(retSave['notifyUserIds']['email']) == 0

    # 2nd user with a match on time, but not on neighborhood.
    userAvailability = { 'userId': users[3]['_id'], 'username': users[3]['username'], 'availableTimesByDay': [
        { 'dayOfWeek': 1, 'times': [ { 'start': '16:00', 'end': '17:00', }], },
    ]}
    retSave = _user_availability.Save(userAvailability)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 0
    assert len(retSave['notifyUserIds']['sms']) == 0
    assert len(retSave['notifyUserIds']['email']) == 0

    # 2nd user that is a match (interest, neighborhood, time)
    userAvailability = { 'userId': users[4]['_id'], 'username': users[4]['username'], 'availableTimesByDay': [
        { 'dayOfWeek': 1, 'times': [ { 'start': '16:00', 'end': '17:00', }], },
    ]}
    retSave = _user_availability.Save(userAvailability)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 0
    assert len(retSave['notifyUserIds']['sms']) == 0
    assert len(retSave['notifyUserIds']['email']) == 0

    # 3rd user, so a match
    dayOfWeek = 1
    startTime = '16:00'
    endTime = '17:00'
    userAvailability = { 'userId': users[5]['_id'], 'username': users[5]['username'], 'availableTimesByDay': [
        { 'dayOfWeek': dayOfWeek, 'times': [ { 'start': startTime, 'end': endTime, }], },
    ]}
    retSave = _user_availability.Save(userAvailability)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 1
    assert len(retSave['weeklyEventsInvited']) == 1
    notifyUserIds = retSave['notifyUserIds']['sms'] + retSave['notifyUserIds']['email']
    assert len(notifyUserIds) == 3
    for notifyUserId in notifyUserIds:
        assert notifyUserId in [users[2]['_id'], users[4]['_id'], users[5]['_id']]
    assert retSave['weeklyEventsCreated'][0]['neighborhoodUName'] == neighborhoods[0]['uName']
    assert retSave['weeklyEventsCreated'][0]['tags'] == ['soccer']
    assert retSave['weeklyEventsCreated'][0]['dayOfWeek'] == dayOfWeek
    assert retSave['weeklyEventsCreated'][0]['startTime'] == startTime
    assert retSave['weeklyEventsCreated'][0]['endTime'] == endTime
    assert retSave['weeklyEventsCreated'][0]['location'] == neighborhoods[0]['location']
    assert retSave['weeklyEventsCreated'][0]['adminUserIds'] == [users[2]['_id'], users[4]['_id'], users[5]['_id']]

    _mongo_mock.CleanUp()

def test_CheckCommonInterestsAndTimesByUserHosts():
    _mongo_mock.InitAllCollections()
    users = _stubs_data.CreateBulk(count = 18, collectionName = 'user')
    neighborhoods = _stubs_data.CreateBulk(count = 1, collectionName = 'neighborhood')
    userNeighborhoods = []
    userInterests = []
    userAvailabilitys = []
    userIdsSharedMeal = []
    userIdsCircle = []
    dayOfWeek = 0
    startTime = '16:00'
    endTime = '17:00'
    for index, user in enumerate(users):
        userNeighborhoods.append({ 'userId': user['_id'], 'neighborhoodUName': neighborhoods[0]['uName'], })
        userAvailabilitys.append({ 'userId': user['_id'], 'username': user['username'], 'availableTimesByDay': [
            { 'dayOfWeek': dayOfWeek, 'times': [ { 'start': startTime, 'end': endTime, }], },
        ], })
        userInterest = { 'userId': user['_id'], 'username': user['username'], 'interests': [], 'hostInterests': [], }
        # shared meal requires 10 to start
        if index < 8:
            userInterest['interests'].append('event_sharedMeal')
        # circle requires 18 to start
        if index < 17:
            userInterest['interests'].append('event_circle')
        userInterests.append(userInterest)
        if index < 11:
            userIdsSharedMeal.append(user['_id'])
        if index < 18:
            userIdsCircle.append(user['_id'])
    for userNeighborhood in userNeighborhoods:
        userNeighborhood = lodash.extend_object({ 'status': 'default', 'motivations': [], }, userNeighborhood)
        _user_neighborhood.Save(userNeighborhood)
    userInterests = _stubs_data.CreateBulk(userInterests, collectionName = 'userInterest')
    userAvailabilitys = _stubs_data.CreateBulk(userAvailabilitys, collectionName = 'userAvailability')

    # 9 of 10 shared meal users
    userInterest =  { '_id': userInterests[8]['_id'], 'userId': users[8]['_id'], 'username': users[8]['username'],
        'interests': [ 'event_sharedMeal', 'event_circle' ] }
    retSave = _user_interest.Save(userInterest)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 0
    assert len(retSave['notifyUserIds']['sms']) == 0
    assert len(retSave['notifyUserIds']['email']) == 0

    # 10 of 10 shared meal users, but no host
    userInterest =  { '_id': userInterests[9]['_id'], 'userId': users[9]['_id'], 'username': users[9]['username'],
        'interests': [ 'event_sharedMeal', 'event_circle' ] }
    retSave = _user_interest.Save(userInterest)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 0
    assert len(retSave['notifyUserIds']['sms']) == 0
    assert len(retSave['notifyUserIds']['email']) == 0

    # 11 of 10 shared meal users, AND host, so match
    userInterest =  { '_id': userInterests[10]['_id'], 'userId': users[10]['_id'], 'username': users[10]['username'],
        'interests': [ 'event_sharedMeal', 'event_circle' ], 'hostInterests': [ 'event_sharedMeal' ] }
    retSave = _user_interest.Save(userInterest)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 1
    assert len(retSave['weeklyEventsInvited']) == 1
    notifyUserIds = retSave['notifyUserIds']['sms'] + retSave['notifyUserIds']['email']
    assert len(notifyUserIds) == 11
    for notifyUserId in notifyUserIds:
        assert notifyUserId in userIdsSharedMeal
    assert retSave['weeklyEventsCreated'][0]['neighborhoodUName'] == neighborhoods[0]['uName']
    assert retSave['weeklyEventsCreated'][0]['tags'] == ['event_sharedMeal']
    assert retSave['weeklyEventsCreated'][0]['dayOfWeek'] == dayOfWeek
    assert retSave['weeklyEventsCreated'][0]['startTime'] == startTime
    assert retSave['weeklyEventsCreated'][0]['endTime'] == endTime
    assert retSave['weeklyEventsCreated'][0]['location'] == neighborhoods[0]['location']
    assert retSave['weeklyEventsCreated'][0]['adminUserIds'] == userIdsSharedMeal

    # 17 of 18 circle users, this is host
    userInterest =  { '_id': userInterests[16]['_id'], 'userId': users[16]['_id'], 'username': users[16]['username'],
        'interests': [ 'event_circle' ], 'hostInterests': [ 'event_circle' ] }
    retSave = _user_interest.Save(userInterest)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 0
    assert len(retSave['weeklyEventsInvited']) == 0
    assert len(retSave['notifyUserIds']['sms']) == 0
    assert len(retSave['notifyUserIds']['email']) == 0

    # 18 of 18 circle users
    userInterest =  { '_id': userInterests[17]['_id'], 'userId': users[17]['_id'], 'username': users[17]['username'],
        'interests': [ 'event_circle' ] }
    retSave = _user_interest.Save(userInterest)
    assert retSave['valid'] == 1
    assert len(retSave['weeklyEventsCreated']) == 1
    assert len(retSave['weeklyEventsInvited']) == 1
    notifyUserIds = retSave['notifyUserIds']['sms'] + retSave['notifyUserIds']['email']
    assert len(notifyUserIds) == 18
    for notifyUserId in notifyUserIds:
        assert notifyUserId in userIdsCircle
    assert retSave['weeklyEventsCreated'][0]['neighborhoodUName'] == neighborhoods[0]['uName']
    assert retSave['weeklyEventsCreated'][0]['tags'] == ['event_circle']
    assert retSave['weeklyEventsCreated'][0]['dayOfWeek'] == dayOfWeek
    assert retSave['weeklyEventsCreated'][0]['startTime'] == startTime
    assert retSave['weeklyEventsCreated'][0]['endTime'] == endTime
    assert retSave['weeklyEventsCreated'][0]['location'] == neighborhoods[0]['location']
    assert retSave['weeklyEventsCreated'][0]['adminUserIds'] == userIdsCircle

    _mongo_mock.CleanUp()
