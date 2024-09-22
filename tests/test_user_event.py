import mongo_mock as _mongo_mock
from event import event as _event
from event import user_event as _user_event
from event import weekly_event as _weekly_event
import mongo_db
from stubs import stubs_data as _stubs_data

def CreateEvent():
    obj = {
        'hostGroupSizeDefault': 3,
        'hostMoneyPerPersonUSD': 5,
    }
    weeklyEvent = _stubs_data.CreateBulk(objs = [ obj ], collectionName = 'weeklyEvent')[0]
    retEvent = _event.GetNextEventFromWeekly(weeklyEvent['_id'])
    event = retEvent['event']

    userEventDefault = {
        'eventId': event['_id'],
        'priceUSD': weeklyEvent['priceUSD'],
        'attendeeCountAsk': 1,
        'hostGroupSizeMax': 0,
    }

    users = _stubs_data.CreateBulk(count = 12, collectionName = 'user')

    return weeklyEvent, event, userEventDefault, users

# Scenarios:
# - More hosts than attendees
#     - fillAll vs not
#     - guests (host and / or attendee) vs not
# - More attendees than hosts
#     - fillAll vs not
#     - guests (host and / or attendee) vs not
def test_CheckAddHostsAndAttendees():
    _mongo_mock.InitAllCollections()


    # No hosts, so do nothing.
    weeklyEvent, event, userEventDefault, users = CreateEvent()
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'attendeeCountAsk': 3, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, default = userEventDefault, collectionName = 'userEvent')
    _user_event.CheckAddHostsAndAttendees(event['_id'])
    for userEvent in userEvents:
        userEventTemp = mongo_db.find_one('userEvent', { 'eventId': event['_id'], 'userId': userEvent['userId'] })['item']
        assert userEventTemp['attendeeCount'] == 0
        assert userEventTemp['attendeeStatus'] == 'pending'
    _weekly_event.Remove(weeklyEvent['_id'])
    _mongo_mock.CleanUp()


    # Host for 4, but only 3 attendees, so do nothing.
    weeklyEvent, event, userEventDefault, users = CreateEvent()
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'hostGroupSizeMax': 4, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, default = userEventDefault, collectionName = 'userEvent')
    _user_event.CheckAddHostsAndAttendees(event['_id'])
    for userEvent in userEvents:
        userEventTemp = mongo_db.find_one('userEvent', { 'eventId': event['_id'], 'userId': userEvent['userId'] })['item']
        assert userEventTemp['attendeeCount'] == 0
        assert userEventTemp['attendeeStatus'] == 'pending'
    _weekly_event.Remove(weeklyEvent['_id'])
    _mongo_mock.CleanUp()


    # 3 hosts at 3 each, 5 non host attendees, so 1st & 2nd hosts are filled, 3rd is not, 5th attendee waiting.
    weeklyEvent, event, userEventDefault, users = CreateEvent()
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'hostGroupSizeMax': 3, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'hostGroupSizeMax': 3, },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], 'hostGroupSizeMax': 3, },
        { 'userId': users[3]['_id'], 'username': users[3]['username'], },
        { 'userId': users[4]['_id'], 'username': users[4]['username'], },
        { 'userId': users[5]['_id'], 'username': users[5]['username'], },
        { 'userId': users[6]['_id'], 'username': users[6]['username'], },
        { 'userId': users[7]['_id'], 'username': users[7]['username'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, default = userEventDefault, collectionName = 'userEvent')
    _user_event.CheckAddHostsAndAttendees(event['_id'])
    for userEvent in userEvents:
        userEventTemp = mongo_db.find_one('userEvent', { 'eventId': event['_id'], 'userId': userEvent['userId'] })['item']
        if userEvent['userId'] in [users[0]['_id'], users[1]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 3
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == weeklyEvent['priceUSD']
            userPayment = mongo_db.find_one('userPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userPayment['amountUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
        elif userEvent['userId'] in [users[2]['_id']]:
            assert userEventTemp['attendeeCount'] == 0
            assert userEventTemp['attendeeStatus'] == 'pending'
            assert userEventTemp['hostGroupSize'] == 0
            assert userEventTemp['hostStatus'] == 'pending'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment == None
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney is None
        elif userEvent['userId'] in [users[3]['_id'], users[4]['_id'], users[5]['_id'], users[6]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
        elif userEvent['userId'] in [users[7]['_id']]:
            assert userEventTemp['attendeeCount'] == 0
            assert userEventTemp['attendeeStatus'] == 'pending'
    _weekly_event.Remove(weeklyEvent['_id'])
    _mongo_mock.CleanUp()


    # fillAll: 5 hosts at 4 each, 4 non host attendees (2 with 1 guest each),
    # so 2nd host does attendee 2 guest 1 and hosts 5 and 4, and host 3 does self.
    weeklyEvent, event, userEventDefault, users = CreateEvent()
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'hostGroupSizeMax': 4, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'hostGroupSizeMax': 4, },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], 'hostGroupSizeMax': 4, },
        { 'userId': users[3]['_id'], 'username': users[3]['username'], 'hostGroupSizeMax': 4, },
        { 'userId': users[4]['_id'], 'username': users[4]['username'], 'hostGroupSizeMax': 4, },
        { 'userId': users[5]['_id'], 'username': users[5]['username'], 'attendeeCountAsk': 2, },
        { 'userId': users[6]['_id'], 'username': users[6]['username'], 'attendeeCountAsk': 2, },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, default = userEventDefault, collectionName = 'userEvent')
    _user_event.CheckAddHostsAndAttendees(event['_id'], fillAll = 1)
    for userEvent in userEvents:
        userEventTemp = mongo_db.find_one('userEvent', { 'eventId': event['_id'], 'userId': userEvent['userId'] })['item']
        if userEvent['userId'] in [users[0]['_id'], users[1]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 4
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == userEventTemp['hostGroupSize'] / weeklyEvent['hostGroupSizeDefault'] * weeklyEvent['priceUSD']
            userPayment = mongo_db.find_one('userPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userPayment['amountUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
        elif userEvent['userId'] in [users[2]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 1
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == userEventTemp['hostGroupSize'] / weeklyEvent['hostGroupSizeDefault'] * weeklyEvent['priceUSD']
            userPayment = mongo_db.find_one('userPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userPayment['amountUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
        elif userEvent['userId'] in [users[3]['_id'], users[4]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 0
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment == None
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney is None
        elif userEvent['userId'] in [users[5]['_id'], users[6]['_id']]:
            assert userEventTemp['attendeeCount'] == 2
            assert userEventTemp['attendeeStatus'] == 'complete'
    _weekly_event.Remove(weeklyEvent['_id'])
    _mongo_mock.CleanUp()


    # 1 host at 3 each with 1 guest, 5 non host attendees, so 1st host is filled, attendees 2-5 waiting.
    weeklyEvent, event, userEventDefault, users = CreateEvent()
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'hostGroupSizeMax': 3, 'attendeeCountAsk': 2, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], },
        { 'userId': users[3]['_id'], 'username': users[3]['username'], },
        { 'userId': users[4]['_id'], 'username': users[4]['username'], },
        { 'userId': users[5]['_id'], 'username': users[5]['username'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, default = userEventDefault, collectionName = 'userEvent')
    _user_event.CheckAddHostsAndAttendees(event['_id'])
    for userEvent in userEvents:
        userEventTemp = mongo_db.find_one('userEvent', { 'eventId': event['_id'], 'userId': userEvent['userId'] })['item']
        if userEvent['userId'] in [users[0]['_id']]:
            assert userEventTemp['attendeeCount'] == 2
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 3
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == userEventTemp['hostGroupSize'] / weeklyEvent['hostGroupSizeDefault'] * weeklyEvent['priceUSD']
            userPayment = mongo_db.find_one('userPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userPayment['amountUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
        elif userEvent['userId'] in [users[1]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 0
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment == None
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney is None
        elif userEvent['userId'] in [users[2]['_id'], users[3]['_id'], users[4]['_id'], users[5]['_id']]:
            assert userEventTemp['attendeeCount'] == 0
            assert userEventTemp['attendeeStatus'] == 'pending'
    _weekly_event.Remove(weeklyEvent['_id'])
    _mongo_mock.CleanUp()


    # fillAll: 1 hosts at 3 each with 1 guest, 6 non host attendees (attendee 1 with 2 guests, attendee 2 with 1 guest),
    # so 1st host is filled, attendee 1 gets 2 * price credit, attendee 2 gets 2 * price credit, attendee 3 gets 1 credit.
    weeklyEvent, event, userEventDefault, users = CreateEvent()
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'hostGroupSizeMax': 3, 'attendeeCountAsk': 2, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'attendeeCountAsk': 3, },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], 'attendeeCountAsk': 2, },
        { 'userId': users[3]['_id'], 'username': users[3]['username'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, default = userEventDefault, collectionName = 'userEvent')
    _user_event.CheckAddHostsAndAttendees(event['_id'], fillAll = 1)
    for userEvent in userEvents:
        userEventTemp = mongo_db.find_one('userEvent', { 'eventId': event['_id'], 'userId': userEvent['userId'] })['item']
        if userEvent['userId'] in [users[0]['_id']]:
            assert userEventTemp['attendeeCount'] == 2
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 3
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == userEventTemp['hostGroupSize'] / weeklyEvent['hostGroupSizeDefault'] * weeklyEvent['priceUSD']
            userPayment = mongo_db.find_one('userPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userPayment['amountUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
        elif userEvent['userId'] in [users[1]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 0
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == 2 * weeklyEvent['priceUSD']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == 0
        elif userEvent['userId'] in [users[2]['_id']]:
            assert userEventTemp['attendeeCount'] == 0
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 0
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == 2 * weeklyEvent['priceUSD']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == 0
        elif userEvent['userId'] in [users[3]['_id']]:
            assert userEventTemp['attendeeCount'] == 0
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 0
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == 1 * weeklyEvent['priceUSD']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == 0
    _weekly_event.Remove(weeklyEvent['_id'])
    _mongo_mock.CleanUp()


    # 1 host at 4 each, host 1 with 4 guests, 5 non host attendees, so 1st host is filled (but 1 guest left over),
    # 5 attendees and host 1 guest waiting.
    weeklyEvent, event, userEventDefault, users = CreateEvent()
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'hostGroupSizeMax': 4, 'attendeeCountAsk': 5, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], },
        { 'userId': users[3]['_id'], 'username': users[3]['username'], },
        { 'userId': users[4]['_id'], 'username': users[4]['username'], },
        { 'userId': users[5]['_id'], 'username': users[5]['username'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, default = userEventDefault, collectionName = 'userEvent')
    _user_event.CheckAddHostsAndAttendees(event['_id'])
    for userEvent in userEvents:
        userEventTemp = mongo_db.find_one('userEvent', { 'eventId': event['_id'], 'userId': userEvent['userId'] })['item']
        if userEvent['userId'] in [users[0]['_id']]:
            assert userEventTemp['attendeeCount'] == 4
            assert userEventTemp['attendeeStatus'] == 'pending'
            assert userEventTemp['hostGroupSize'] == 4
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == userEventTemp['hostGroupSize'] / weeklyEvent['hostGroupSizeDefault'] * weeklyEvent['priceUSD']
            userPayment = mongo_db.find_one('userPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userPayment['amountUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
        elif userEvent['userId'] in [users[1]['_id'], users[2]['_id'], users[3]['_id'], users[4]['_id']]:
            assert userEventTemp['attendeeCount'] == 0
            assert userEventTemp['attendeeStatus'] == 'pending'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment == None
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney is None
    _weekly_event.Remove(weeklyEvent['_id'])
    _mongo_mock.CleanUp()


    # 2 hosts at 4 each, host 1 with 4 guests, 1 non host attendee, so 1st host is filled (but 1 guest left over),
    # 2nd host has attendee1 and host 1 guest.
    weeklyEvent, event, userEventDefault, users = CreateEvent()
    userEvents = [
        { 'userId': users[0]['_id'], 'username': users[0]['username'], 'hostGroupSizeMax': 4, 'attendeeCountAsk': 5, },
        { 'userId': users[1]['_id'], 'username': users[1]['username'], 'hostGroupSizeMax': 4, },
        { 'userId': users[2]['_id'], 'username': users[2]['username'], },
    ]
    userEvents = _stubs_data.CreateBulk(objs = userEvents, default = userEventDefault, collectionName = 'userEvent')
    _user_event.CheckAddHostsAndAttendees(event['_id'], fillAll = 1)
    for userEvent in userEvents:
        userEventTemp = mongo_db.find_one('userEvent', { 'eventId': event['_id'], 'userId': userEvent['userId'] })['item']
        if userEvent['userId'] in [users[0]['_id']]:
            assert userEventTemp['attendeeCount'] == 5
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 4
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == userEventTemp['hostGroupSize'] / weeklyEvent['hostGroupSizeDefault'] * weeklyEvent['priceUSD']
            userPayment = mongo_db.find_one('userPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userPayment['amountUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
        elif userEvent['userId'] in [users[1]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
            assert userEventTemp['hostGroupSize'] == 3
            assert userEventTemp['hostStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment['amountUSD'] == userEventTemp['hostGroupSize'] / weeklyEvent['hostGroupSizeDefault'] * weeklyEvent['priceUSD']
            userPayment = mongo_db.find_one('userPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userPayment['amountUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney['balanceUSD'] == weeklyEvent['hostMoneyPerPersonUSD'] * userEventTemp['hostGroupSize']
        elif userEvent['userId'] in [users[2]['_id']]:
            assert userEventTemp['attendeeCount'] == 1
            assert userEventTemp['attendeeStatus'] == 'complete'
            userCreditPayment = mongo_db.find_one('userCreditPayment', { 'forType': 'event', 'forId': event['_id'], 'userId': userEvent['userId'] })['item']
            assert userCreditPayment == None
            userMoney = mongo_db.find_one('userMoney', { 'userId': userEvent['userId'] })['item']
            assert userMoney is None
    _weekly_event.Remove(weeklyEvent['_id'])
    _mongo_mock.CleanUp()
