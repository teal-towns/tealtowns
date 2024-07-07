import date_time
import mongo_mock as _mongo_mock
import mongo_db
from neighborhood import user_neighborhood_weekly_update as _user_neighborhood_weekly_update
from stubs import stubs_data as _stubs_data

def test_Save():
    _mongo_mock.InitAllCollections()

    userId1 = 'user1'
    stringKeyVals = { 'userId': userId1 }
    userFeedbacksIn = [
        { 'userId': userId1, 'attended': 'yes', 'createdAt': '2024-04-01T17:00:00+00:00' },
        { 'userId': userId1, 'attended': 'no', 'createdAt': '2024-05-02T17:00:00+00:00' },
        { 'userId': userId1, 'attended': 'yes', 'createdAt': '2024-05-03T17:00:00+00:00' },
        { 'userId': userId1, 'attended': 'yes', 'createdAt': '2024-05-04T17:00:00+00:00' },
    ]
    userFeedbacks = _stubs_data.CreateBulk(objs = userFeedbacksIn, collectionName = 'userFeedback', saveInDatabase = 0)
    for userFeedback in userFeedbacks:
        mongo_db.insert_one('userFeedback', userFeedback, now = date_time.from_string(userFeedback['createdAt']))

    # Wed; should start on Mon 4/29
    now = date_time.from_string('2024-05-01 09:00:00+00:00')
    userNeighborhoodWeeklyUpdate = { 'userId': userId1, 'neighborhoodUName': 'neighborhood1', 'inviteCount': 3, }
    _user_neighborhood_weekly_update.Save(userNeighborhoodWeeklyUpdate, now = now)
    userNeighborhoodWeeklyUpdates = _user_neighborhood_weekly_update.Search(stringKeyVals,
        withEventsAttendedCount = 1, sortKeys = 'start')['userNeighborhoodWeeklyUpdates']
    # userNeighborhoodWeeklyUpdates = mongo_db.find('userNeighborhoodWeeklyUpdate', {'userId': userId1})['items']
    assert len(userNeighborhoodWeeklyUpdates) == 1
    assert userNeighborhoodWeeklyUpdates[0]['inviteCount'] == userNeighborhoodWeeklyUpdate['inviteCount']
    assert userNeighborhoodWeeklyUpdates[0]['start'] == '2024-04-29T00:00:00+00:00'
    assert 'eventsAttendedCount' not in userNeighborhoodWeeklyUpdates[0]

    # Update within same week.
    now = date_time.from_string('2024-05-02 09:00:00+00:00')
    userNeighborhoodWeeklyUpdate = { 'userId': userId1, 'neighborhoodUName': 'neighborhood1', 'inviteCount': 5, }
    _user_neighborhood_weekly_update.Save(userNeighborhoodWeeklyUpdate, now = now)
    userNeighborhoodWeeklyUpdates = _user_neighborhood_weekly_update.Search(stringKeyVals,
        withEventsAttendedCount = 1, sortKeys = 'start')['userNeighborhoodWeeklyUpdates']
    assert len(userNeighborhoodWeeklyUpdates) == 1
    assert userNeighborhoodWeeklyUpdates[0]['inviteCount'] == userNeighborhoodWeeklyUpdate['inviteCount']
    assert userNeighborhoodWeeklyUpdates[0]['start'] == '2024-04-29T00:00:00+00:00'
    assert 'eventsAttendedCount' not in userNeighborhoodWeeklyUpdates[0]

    # Add in future week
    now = date_time.from_string('2024-05-07 09:00:00+00:00')
    userNeighborhoodWeeklyUpdate = { 'userId': userId1, 'neighborhoodUName': 'neighborhood1', 'inviteCount': 10, }
    _user_neighborhood_weekly_update.Save(userNeighborhoodWeeklyUpdate, now = now)
    userNeighborhoodWeeklyUpdates = _user_neighborhood_weekly_update.Search(stringKeyVals,
        withEventsAttendedCount = 1, sortKeys = 'start')['userNeighborhoodWeeklyUpdates']
    assert len(userNeighborhoodWeeklyUpdates) == 2
    assert userNeighborhoodWeeklyUpdates[1]['inviteCount'] == userNeighborhoodWeeklyUpdate['inviteCount']
    assert userNeighborhoodWeeklyUpdates[1]['start'] == '2024-05-06T00:00:00+00:00'
    assert 'eventsAttendedCount' not in userNeighborhoodWeeklyUpdates[1]
    assert userNeighborhoodWeeklyUpdates[0]['start'] == '2024-04-29T00:00:00+00:00'
    assert userNeighborhoodWeeklyUpdates[0]['eventsAttendedCount'] == 2

    _mongo_mock.CleanUp()
