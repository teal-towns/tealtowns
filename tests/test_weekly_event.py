import datetime

import date_time
import mongo_db
import mongo_mock as _mongo_mock
from common import mongo_db_crud as _mongo_db_crud
from event import event as _event
from event import event_payment as _event_payment
from event import user_event as _user_event
from event import user_weekly_event as _user_weekly_event
from event import weekly_event as _weekly_event
from stubs import stubs_data as _stubs_data
from user_payment import user_payment as _user_payment

# Flow:
# 1. create weeklyEvent
# 2. sign up for event (weeklyEvent or individual). Pay to sign up.
#     - weekly subscribers are auto-signed up for individual events each week BUT can manually add host & guest counts each week
# Things to test:
# - event sign up
#     - host & guest options
#     - on sign up, check next host & if have enough attendees, add them & give host money and event credit
#     - payment: subscriptions vs single events vs credits vs money balance
# - rsvpDeadlineHours
#     - auto create new event & add weekly event (subscribers) (who have active payment status) to new event
#        - note: signs up after this will go to next week event
#     - if extra hosts and attendees, add them (even if not a full group)
#     - any extra attendees get 1 credit (can not go this week as not enough hosts)
def test_WeeklyEventFlow():
    _mongo_mock.InitAllCollections()

    userDefault = { 'phoneNumberVerified': 1, }
    users = _stubs_data.CreateBulk(count = 10, collectionName = 'user', default = userDefault)

    weeklyEvent = {
        "type": "sharedMeal",
        "title": "Shared Meal",
        "dayOfWeek": 6,
        "startTime": '17:00',
        "endTime": '18:30',
        "timezone": "",
        "location": {
            "type": "Point",
            "coordinates": [ -122.03, 37.97 ],
        },
        "adminUserIds": [],
        "hostGroupSizeDefault": 4,
        "hostMoneyPerPersonUSD": 4,
        "priceUSD": 10,
        "rsvpDeadlineHours": 72,
    }

    # Add money balance for some users 1.
    userAmountsCurrent = [0, 1000, 0, 0, 0, 0, 0, 0]
    for index, userAmount in enumerate(userAmountsCurrent):
        if userAmount > 0:
            _user_payment.AddPayment(users[index]['_id'], userAmount, 'testType', 'testId')
    userCreditsCurrent = [0,0,0,0,0,0,0,0,0]

    # Week 1:
    # - User 1 creates weekly event, then signs up (pays with money balance) for a single event (this auto creates an event for this week).
    # - User 2 signs up (pays) for a monthly subscription to the weekly event; user 2 is added to this week's event
    # - User 3 signs up as a host; pays for a single event
    # - User 4 signs up for a yearly subscription with 2 guests on the subscription.
    #     - This triggers: there is a host, so User 3 is paid $16 and given 1 credit (cooks for 4 people).
    # - RSVP Deadline passes.
    #     - User 4 gets 2 credits (since 2 guests could not join)
    #     - Since there are subscription users, a new event for next week is auto created and Users 2 and 4 (with 2 guests too) are signed up (added to userEvent).
    weeklyEvent['adminUserIds'] = [ users[1]['_id'] ]
    retWeeklyEvent = _weekly_event.Save(weeklyEvent)
    weeklyEvent = retWeeklyEvent['weeklyEvent']
    assert len(weeklyEvent['uName']) > 0
    assert weeklyEvent['timezone'] == 'America/Los_Angeles'
    subscriptionPrices = _event_payment.GetSubscriptionDiscounts(weeklyEvent['priceUSD'], weeklyEvent['hostGroupSizeDefault'])

    # User 1
    # Wednesday, so next event is this Sunday.
    now = date_time.from_string('2024-03-20 09:00:00-07:00')
    retEvent = _event.GetNextEventFromWeekly(weeklyEvent['_id'], now = now)
    event1 = retEvent['event']
    assert event1['start'] == '2024-03-24T17:00:00-07:00'
    user1Event = {
        'eventId': event1['_id'],
        'userId': users[1]['_id'],
        'hostGroupSizeMax': 0,
        'attendeeCountAsk': 1,
    }
    retPayCheck = _user_event.CheckAndTakePayment(users[1]['_id'], event1['_id'], user1Event['attendeeCountAsk'])
    assert retPayCheck['availableUSD'] == userAmountsCurrent[1]
    assert retPayCheck['spotsToPayFor'] == 1
    assert retPayCheck['amountToPay'] == weeklyEvent['priceUSD']
    retUserEvent = _user_event.Save(user1Event, 'userMoney')
    assert retUserEvent['valid'] == 1
    assert retUserEvent['spotsPaidFor'] == 1
    assert len(retUserEvent['userEvent']['_id']) > 0
    userAmountsCurrent[1] -= weeklyEvent['priceUSD']
    assert retUserEvent['availableUSD'] == userAmountsCurrent[1]
    assert retUserEvent['availableCredits'] == 0
    assert len(retUserEvent['notifyUserIdsHosts']['sms']) == 0
    assert len(retUserEvent['notifyUserIdsAttendees']['sms']) == 0

    # User 2
    now = now + datetime.timedelta(hours = 1)
    user2PaymentSubscription = {
        'userId': users[2]['_id'],
        'amountUSD': subscriptionPrices['monthlyPrice'],
        'recurringInterval': 'month',
        'recurringIntervalCount': 1,
        'forType': 'weeklyEvent',
        'forId': weeklyEvent['_id'],
        'status': 'complete',
        'stripeId': 'testStripeId',
    }
    _mongo_db_crud.Save('userPaymentSubscription', user2PaymentSubscription)
    user2WeeklyEvent = {
        'weeklyEventId': weeklyEvent['_id'],
        'userId': users[2]['_id'],
        'attendeeCountAsk': 1,
    }
    retTemp = _user_weekly_event.Save(user2WeeklyEvent, now = now)
    assert retTemp['valid'] == 1
    assert len(retTemp['userWeeklyEvent']['_id']) > 0
    assert len(retTemp['notifyUserIdsHosts']['sms']) == 0
    assert len(retTemp['notifyUserIdsAttendees']['sms']) == 0
    userEvent = mongo_db.find_one('userEvent', {'eventId': event1['_id'], 'userId': users[2]['_id']})['item']
    assert userEvent['attendeeCountAsk'] == 1

    # User 3
    now = now + datetime.timedelta(hours = 1)
    user3Payment = {
        'userId': users[3]['_id'],
        'amountUSD': -1 * weeklyEvent['priceUSD'],
        'amountUSDPreFee': -1 * weeklyEvent['priceUSD'],
        'forType': 'event',
        'forId': event1['_id'],
        'status': 'complete',
    }
    _mongo_db_crud.Save('userPayment', user3Payment)
    user3Event = {
        'eventId': event1['_id'],
        'userId': users[3]['_id'],
        'hostGroupSizeMax': 4,
        'attendeeCountAsk': 1,
    }
    retUserEvent = _user_event.Save(user3Event, 'paid')
    assert retUserEvent['valid'] == 1
    assert retUserEvent['spotsPaidFor'] == 1
    assert len(retUserEvent['userEvent']['_id']) > 0
    assert len(retUserEvent['notifyUserIdsHosts']['sms']) == 0
    assert len(retUserEvent['notifyUserIdsAttendees']['sms']) == 0

    # User 4
    now = now + datetime.timedelta(hours = 1)
    attendeeCountAsk = 3
    user4PaymentSubscription = {
        'userId': users[4]['_id'],
        'amountUSD': subscriptionPrices['yearlyPrice'] * attendeeCountAsk,
        'recurringInterval': 'year',
        'recurringIntervalCount': 1,
        'forType': 'weeklyEvent',
        'forId': weeklyEvent['_id'],
        'status': 'complete',
        'stripeId': 'testStripeId',
    }
    _mongo_db_crud.Save('userPaymentSubscription', user4PaymentSubscription)
    user4WeeklyEvent = {
        'weeklyEventId': weeklyEvent['_id'],
        'userId': users[4]['_id'],
        'attendeeCountAsk': attendeeCountAsk,
    }
    retTemp = _user_weekly_event.Save(user4WeeklyEvent, now = now)
    assert retTemp['valid'] == 1
    assert len(retTemp['userWeeklyEvent']['_id']) > 0
    assert len(retTemp['notifyUserIdsHosts']['sms']) == 1
    for userId in retTemp['notifyUserIdsHosts']['sms']:
        assert userId in [users[3]['_id']]
    # Host is already notified as host, so not as attendee.
    assert len(retTemp['notifyUserIdsAttendees']['sms']) == 4 - 1
    for userId in retTemp['notifyUserIdsAttendees']['sms']:
        assert userId in [users[1]['_id'], users[2]['_id'], users[4]['_id']]
    userEvent = mongo_db.find_one('userEvent', {'eventId': event1['_id'], 'userId': users[4]['_id']})['item']
    assert userEvent['attendeeCountAsk'] == 3
    # User 3 host is now filled.
    userEvents = mongo_db.find('userEvent', {'eventId': event1['_id']})['items']
    for userEvent in userEvents:
        if userEvent['userId'] in [users[1]['_id'], users[2]['_id']]:
            assert userEvent['attendeeCount'] == 1
            assert userEvent['attendeeStatus'] == 'complete'
        elif userEvent['userId'] in [users[3]['_id']]:
            assert userEvent['attendeeCount'] == 1
            assert userEvent['attendeeStatus'] == 'complete'
            assert userEvent['hostStatus'] == 'complete'
            assert userEvent['hostGroupSize'] == 4
            assert userEvent['creditsEarned'] == 1
        elif userEvent['userId'] in [users[4]['_id']]:
            assert userEvent['attendeeCount'] == 1
            assert userEvent['attendeeStatus'] == 'pending'
    userMoney = mongo_db.find_one('userMoney', {'userId': users[3]['_id']})['item']
    userAmountsCurrent[3] += weeklyEvent['hostMoneyPerPersonUSD'] * 4
    assert userMoney['balanceUSD'] == userAmountsCurrent[3]
    userCreditsCurrent[3] += 1

    # RSVP Deadline
    # Saturday, so passed deadline.
    now = date_time.from_string('2024-03-23 09:00:00-07:00')
    retWeekly = _weekly_event.CheckRSVPDeadline(weeklyEvent['_id'], now = now)
    assert len(retWeekly['notifyUserIdsSubscribers']['sms']) == 2
    for userId in retWeekly['notifyUserIdsSubscribers']['sms']:
        assert userId in [users[2]['_id'], users[4]['_id']]
    assert len(retWeekly['notifyUserIdsUnused']['sms']) == 1
    for userId in retWeekly['notifyUserIdsUnused']['sms']:
        assert userId in [users[4]['_id']]
    assert len(retWeekly['notifyUserIdsHosts']['sms']) == 0
    assert len(retWeekly['notifyUserIdsAttendees']['sms']) == 0

    credits = _user_event.GetUserEventCredits(users[4]['_id'], weeklyEvent['_id'])
    userCreditsCurrent[4] += 2
    assert credits == userCreditsCurrent[4]
    retEvent = _event.GetNextEventFromWeekly(weeklyEvent['_id'], now = now)
    event2 = retEvent['event']
    assert event2['start'] == '2024-03-31T17:00:00-07:00'
    userEvents = mongo_db.find('userEvent', {'eventId': event2['_id']})['items']
    for userEvent in userEvents:
        if userEvent['userId'] in [users[2]['_id']]:
            assert userEvent['attendeeCountAsk'] == 1
        elif userEvent['userId'] in [users[4]['_id']]:
            assert userEvent['attendeeCountAsk'] == 3



    # Week 2:
    # - User 2 signs up to host 4 people
    #   - User 4 and 2 guests plus User 2 are the attendees for User 2 host (who is paid $16).
    # - User 3 signs up again this week to host. Has 1 credit, so that is used instead of payment.
    # - User 5 signs up.
    # - User 6 signs up for a monthly subscription
    # - RSVP deadline passes; User 3 hosts 3 people and gets 0.75 credits (and $12).
    #     - A new event for next week is auto created with Users 2, 4 (plus 2 guests) and 6 added.
    # User 2
    # Sunday night
    now = date_time.from_string('2024-03-24 18:00:00-07:00')
    user2Event = mongo_db.find_one('userEvent', {'eventId': event2['_id'], 'userId': users[2]['_id']})['item']
    user2Event['hostGroupSizeMax'] = 4
    user2Event['hostStatus'] = 'pending'
    retUserEvent = _user_event.Save(user2Event, 'paidSubscription')
    assert retUserEvent['valid'] == 1
    assert retUserEvent['spotsPaidFor'] == 1
    assert retUserEvent['userEvent']['_id'] == user2Event['_id']
    assert len(retUserEvent['notifyUserIdsHosts']['sms']) == 1
    for userId in retUserEvent['notifyUserIdsHosts']['sms']:
        assert userId in [users[2]['_id']]
    assert len(retUserEvent['notifyUserIdsAttendees']['sms']) == 2 - 1
    for userId in retUserEvent['notifyUserIdsAttendees']['sms']:
        assert userId in [users[4]['_id']]
    userEvents = mongo_db.find('userEvent', {'eventId': event2['_id']})['items']
    for userEvent in userEvents:
        if userEvent['userId'] in [users[2]['_id']]:
            assert userEvent['attendeeCount'] == 1
            assert userEvent['attendeeStatus'] == 'complete'
            assert userEvent['hostStatus'] == 'complete'
            assert userEvent['hostGroupSize'] == 4
            assert userEvent['creditsEarned'] == 1
        elif userEvent['userId'] in [users[4]['_id']]:
            assert userEvent['attendeeCount'] == 3
            assert userEvent['attendeeStatus'] == 'complete'
    userMoney = mongo_db.find_one('userMoney', {'userId': users[2]['_id']})['item']
    userAmountsCurrent[2] += weeklyEvent['hostMoneyPerPersonUSD'] * 4
    assert userMoney['balanceUSD'] == userAmountsCurrent[2]
    userCreditsCurrent[2] += 1

    # User 3
    now = now + datetime.timedelta(days = 1)
    retPay = _user_event.CheckAndTakePayment(users[3]['_id'], event2['_id'], 1)
    assert retPay['spotsToPayFor'] == 1
    assert retPay['availableCredits'] == userCreditsCurrent[3]
    user3Event = {
        'eventId': event2['_id'],
        'userId': users[3]['_id'],
        'hostGroupSizeMax': 4,
        'attendeeCountAsk': 1,
    }
    retUserEvent = _user_event.Save(user3Event, 'credits')
    assert retUserEvent['valid'] == 1
    assert retUserEvent['spotsPaidFor'] == 1
    assert retUserEvent['userEvent']['creditsRedeemed'] == 1
    assert len(retUserEvent['userEvent']['_id']) > 0
    assert len(retUserEvent['notifyUserIdsHosts']['sms']) == 0
    assert len(retUserEvent['notifyUserIdsAttendees']['sms']) == 0
    credits = _user_event.GetUserEventCredits(users[3]['_id'], weeklyEvent['_id'])
    userCreditsCurrent[3] -= 1
    assert credits == userCreditsCurrent[3]

    # User 5
    now = now + datetime.timedelta(hours = 1)
    user5Payment = {
        'userId': users[5]['_id'],
        'amountUSD': -1 * weeklyEvent['priceUSD'],
        'amountUSDPreFee': -1 * weeklyEvent['priceUSD'],
        'forType': 'event',
        'forId': event2['_id'],
        'status': 'complete',
    }
    _mongo_db_crud.Save('userPayment', user5Payment)
    user5Event = {
        'eventId': event2['_id'],
        'userId': users[5]['_id'],
        'attendeeCountAsk': 1,
    }
    retUserEvent = _user_event.Save(user5Event, 'paid')
    assert retUserEvent['valid'] == 1
    assert retUserEvent['spotsPaidFor'] == 1
    assert len(retUserEvent['userEvent']['_id']) > 0
    assert len(retUserEvent['notifyUserIdsHosts']['sms']) == 0
    assert len(retUserEvent['notifyUserIdsAttendees']['sms']) == 0

    # User 6
    now = now + datetime.timedelta(hours = 1)
    user6PaymentSubscription = {
        'userId': users[6]['_id'],
        'amountUSD': subscriptionPrices['monthlyPrice'],
        'recurringInterval': 'month',
        'recurringIntervalCount': 1,
        'forType': 'weeklyEvent',
        'forId': weeklyEvent['_id'],
        'status': 'complete',
        'stripeId': 'testStripeId',
    }
    _mongo_db_crud.Save('userPaymentSubscription', user6PaymentSubscription)
    user6WeeklyEvent = {
        'weeklyEventId': weeklyEvent['_id'],
        'userId': users[6]['_id'],
        'attendeeCountAsk': 1,
    }
    retTemp = _user_weekly_event.Save(user6WeeklyEvent, now = now)
    assert retTemp['valid'] == 1
    assert len(retTemp['userWeeklyEvent']['_id']) > 0
    assert len(retTemp['notifyUserIdsHosts']['sms']) == 0
    assert len(retTemp['notifyUserIdsAttendees']['sms']) == 0
    userEvent = mongo_db.find_one('userEvent', {'eventId': event2['_id'], 'userId': users[6]['_id']})['item']
    assert userEvent['attendeeCountAsk'] == 1

    # RSVP Deadline
    # Friday, so passed deadline.
    now = date_time.from_string('2024-03-29 12:00:00-07:00')
    retWeekly = _weekly_event.CheckRSVPDeadline(weeklyEvent['_id'], now = now)
    assert len(retWeekly['notifyUserIdsSubscribers']['sms']) == 3
    for userId in retWeekly['notifyUserIdsSubscribers']['sms']:
        assert userId in [users[2]['_id'], users[4]['_id'], users[6]['_id']]
    assert len(retWeekly['notifyUserIdsUnused']['sms']) == 0
    assert len(retWeekly['notifyUserIdsHosts']['sms']) == 1
    for userId in retWeekly['notifyUserIdsHosts']['sms']:
        assert userId == users[3]['_id']
    assert len(retWeekly['notifyUserIdsAttendees']['sms']) == 3 - 1
    for userId in retWeekly['notifyUserIdsAttendees']['sms']:
        assert userId in [users[5]['_id'], users[6]['_id']]

    credits = _user_event.GetUserEventCredits(users[3]['_id'], weeklyEvent['_id'])
    userCreditsCurrent[3] += 0.75
    assert credits == userCreditsCurrent[3]
    userMoney = mongo_db.find_one('userMoney', {'userId': users[3]['_id']})['item']
    userAmountsCurrent[3] += weeklyEvent['hostMoneyPerPersonUSD'] * 3
    assert userMoney['balanceUSD'] == userAmountsCurrent[3]
    retEvent = _event.GetNextEventFromWeekly(weeklyEvent['_id'], now = now)
    event3 = retEvent['event']
    assert event3['start'] == '2024-04-07T17:00:00-07:00'
    userEvents = mongo_db.find('userEvent', {'eventId': event3['_id']})['items']
    for userEvent in userEvents:
        if userEvent['userId'] in [users[2]['_id'], users[6]['_id']]:
            assert userEvent['attendeeCountAsk'] == 1
        elif userEvent['userId'] in [users[4]['_id']]:
            assert userEvent['attendeeCountAsk'] == 3



    # Week 3:
    # - User 7 signs up for a single event.
    # - User 3 signs up to host 4 people; Users 3, 2, 4 (and 1 of 2 guests) are added; User 3 gets $16 and 1 event credit. User 4 guest 2 and Users 6 and 7 must wait.
    # - User 8 signs up for a single event with 1 guest.
    # - RSVP deadline passes; not enough hosts so Users 6, 7, 8 (and 1 guest) and User 4 guest 2 may not join and each gets 1 event credit (User 8 gets 2 - for self and 1 guest) for the future.
    #   - Users 2, 4, 6 are added for next week's event.

    # User 7
    # Saturday (for the following Sunday)
    now = date_time.from_string('2024-03-30 16:00:00-07:00')
    user7Payment = {
        'userId': users[7]['_id'],
        'amountUSD': -1 * weeklyEvent['priceUSD'],
        'amountUSDPreFee': -1 * weeklyEvent['priceUSD'],
        'forType': 'event',
        'forId': event3['_id'],
        'status': 'complete',
    }
    _mongo_db_crud.Save('userPayment', user7Payment)
    user7Event = {
        'eventId': event3['_id'],
        'userId': users[7]['_id'],
        'attendeeCountAsk': 1,
    }
    retUserEvent = _user_event.Save(user7Event, 'paid')
    assert retUserEvent['valid'] == 1
    assert retUserEvent['spotsPaidFor'] == 1
    assert len(retUserEvent['userEvent']['_id']) > 0
    assert len(retUserEvent['notifyUserIdsHosts']['sms']) == 0
    assert len(retUserEvent['notifyUserIdsAttendees']['sms']) == 0

    # User 3
    now = now + datetime.timedelta(days = 1)
    retPay = _user_event.CheckAndTakePayment(users[3]['_id'], event3['_id'], 1)
    assert retPay['spotsToPayFor'] == 1
    assert retPay['availableCredits'] == userCreditsCurrent[3]
    user3Payment = {
        'userId': users[3]['_id'],
        'amountUSD': -1 * weeklyEvent['priceUSD'],
        'amountUSDPreFee': -1 * weeklyEvent['priceUSD'],
        'forType': 'event',
        'forId': event3['_id'],
        'status': 'complete',
    }
    _mongo_db_crud.Save('userPayment', user3Payment)
    user3Event = {
        'eventId': event3['_id'],
        'userId': users[3]['_id'],
        'hostGroupSizeMax': 4,
        'attendeeCountAsk': 1,
    }
    retUserEvent = _user_event.Save(user3Event, 'paid')
    assert retUserEvent['valid'] == 1
    assert retUserEvent['spotsPaidFor'] == 1
    assert retUserEvent['userEvent']['creditsRedeemed'] == 0
    assert len(retUserEvent['userEvent']['_id']) > 0
    assert len(retUserEvent['notifyUserIdsHosts']['sms']) == 1
    for userId in retUserEvent['notifyUserIdsHosts']['sms']:
        assert userId in [users[3]['_id']]
    assert len(retUserEvent['notifyUserIdsAttendees']['sms']) == 3 - 1
    for userId in retUserEvent['notifyUserIdsAttendees']['sms']:
        assert userId in [users[2]['_id'], users[4]['_id']]
    userEvents = mongo_db.find('userEvent', {'eventId': event3['_id']})['items']
    for userEvent in userEvents:
        if userEvent['userId'] in [users[3]['_id']]:
            assert userEvent['attendeeCount'] == 1
            assert userEvent['attendeeStatus'] == 'complete'
            assert userEvent['hostStatus'] == 'complete'
            assert userEvent['hostGroupSize'] == 4
            assert userEvent['creditsEarned'] == 1
        elif userEvent['userId'] in [users[4]['_id']]:
            assert userEvent['attendeeCount'] == 2
            assert userEvent['attendeeStatus'] == 'pending'
        elif userEvent['userId'] in [users[2]['_id']]:
            assert userEvent['attendeeCount'] == 1
            assert userEvent['attendeeStatus'] == 'complete'
        elif userEvent['userId'] in [users[6]['_id'], users[7]['_id']]:
            assert userEvent['attendeeCount'] == 0
            assert userEvent['attendeeStatus'] == 'pending'
    userMoney = mongo_db.find_one('userMoney', {'userId': users[3]['_id']})['item']
    userAmountsCurrent[3] += weeklyEvent['hostMoneyPerPersonUSD'] * 4
    assert userMoney['balanceUSD'] == userAmountsCurrent[3]
    credits = _user_event.GetUserEventCredits(users[3]['_id'], weeklyEvent['_id'])
    userCreditsCurrent[3] += 1
    assert credits == userCreditsCurrent[3]

    # User 8
    now = now + datetime.timedelta(hours = 1)
    attendeeCountAsk = 2
    user8Payment = {
        'userId': users[8]['_id'],
        'amountUSD': -1 * weeklyEvent['priceUSD'] * attendeeCountAsk,
        'amountUSDPreFee': -1 * weeklyEvent['priceUSD'] * attendeeCountAsk,
        'forType': 'event',
        'forId': event3['_id'],
        'status': 'complete',
    }
    _mongo_db_crud.Save('userPayment', user8Payment)
    user8Event = {
        'eventId': event3['_id'],
        'userId': users[8]['_id'],
        'attendeeCountAsk': attendeeCountAsk,
    }
    retUserEvent = _user_event.Save(user8Event, 'paid')
    assert retUserEvent['valid'] == 1
    assert retUserEvent['spotsPaidFor'] == 2
    assert len(retUserEvent['userEvent']['_id']) > 0
    assert len(retUserEvent['notifyUserIdsHosts']['sms']) == 0
    assert len(retUserEvent['notifyUserIdsAttendees']['sms']) == 0

    # RSVP Deadline
    # Friday, so passed deadline.
    now = date_time.from_string('2024-04-05 12:00:00-07:00')
    retWeekly = _weekly_event.CheckRSVPDeadline(weeklyEvent['_id'], now = now)
    assert len(retWeekly['notifyUserIdsSubscribers']['sms']) == 3
    for userId in retWeekly['notifyUserIdsSubscribers']['sms']:
        assert userId in [users[2]['_id'], users[4]['_id'], users[6]['_id']]
    assert len(retWeekly['notifyUserIdsUnused']['sms']) == 4
    for userId in retWeekly['notifyUserIdsUnused']['sms']:
        assert userId in [users[4]['_id'], users[6]['_id'], users[7]['_id'], users[8]['_id']]
    assert len(retWeekly['notifyUserIdsHosts']['sms']) == 0
    assert len(retWeekly['notifyUserIdsAttendees']['sms']) == 0

    credits = _user_event.GetUserEventCredits(users[4]['_id'], weeklyEvent['_id'])
    userCreditsCurrent[4] += 1
    assert credits == userCreditsCurrent[4]
    credits = _user_event.GetUserEventCredits(users[6]['_id'], weeklyEvent['_id'])
    userCreditsCurrent[6] += 1
    assert credits == userCreditsCurrent[6]
    credits = _user_event.GetUserEventCredits(users[7]['_id'], weeklyEvent['_id'])
    userCreditsCurrent[7] += 1
    assert credits == userCreditsCurrent[7]
    credits = _user_event.GetUserEventCredits(users[8]['_id'], weeklyEvent['_id'])
    userCreditsCurrent[8] += 2
    assert credits == userCreditsCurrent[8]
    userEvents = mongo_db.find('userEvent', {'eventId': event3['_id']})['items']
    # - RSVP deadline passes; not enough hosts so Users 6, 7, 8 (and 1 guest) and User 4 guest 2 may not join and each gets 1 event credit (User 8 gets 2 - for self and 1 guest) for the future.

    for userEvent in userEvents:
        if userEvent['userId'] in [users[6]['_id'], users[7]['_id']]:
            assert userEvent['attendeeCount'] == 0
            assert userEvent['attendeeStatus'] == 'complete'
            assert userEvent['creditsEarned'] == 1
        elif userEvent['userId'] in [users[4]['_id']]:
            assert userEvent['attendeeCount'] == 2
            assert userEvent['attendeeStatus'] == 'complete'
            assert userEvent['creditsEarned'] == 1
        elif userEvent['userId'] in [users[8]['_id']]:
            assert userEvent['attendeeCount'] == 0
            assert userEvent['attendeeStatus'] == 'complete'
            assert userEvent['creditsEarned'] == 2
    retEvent = _event.GetNextEventFromWeekly(weeklyEvent['_id'], now = now)
    event4 = retEvent['event']
    assert event4['start'] == '2024-04-14T17:00:00-07:00'
    userEvents = mongo_db.find('userEvent', {'eventId': event4['_id']})['items']
    for userEvent in userEvents:
        if userEvent['userId'] in [users[2]['_id'], users[6]['_id']]:
            assert userEvent['attendeeCountAsk'] == 1
        elif userEvent['userId'] in [users[4]['_id']]:
            assert userEvent['attendeeCountAsk'] == 3

    _mongo_mock.CleanUp()
