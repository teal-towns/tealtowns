import date_time
from event import event as _event
import mongo_db
import mongo_mock as _mongo_mock
from stubs import stubs_data as _stubs_data
from user_payment import user_payment as _user_payment

def test_GetSubscriptionPaymentsRemaining():
    userPaymentSubscription = {
        'createdAt': '2024-03-20 09:00:00+00:00',
        'recurringInterval': 'month',
        'recurringIntervalCount': 1,
    }
    now = date_time.from_string('2024-03-21 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 4

    now = date_time.from_string('2024-03-31 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 3

    now = date_time.from_string('2024-04-04 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 2

    now = date_time.from_string('2024-04-18 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 0

    userPaymentSubscription = {
        'createdAt': '2024-03-20 09:00:00+00:00',
        'recurringInterval': 'year',
        'recurringIntervalCount': 1,
    }
    now = date_time.from_string('2024-03-21 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 52

    now = date_time.from_string('2024-04-21 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 47

    now = date_time.from_string('2024-01-02 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 11

    # Next year
    now = date_time.from_string('2025-05-02 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 46

    userPaymentSubscription = {
        'createdAt': '2024-03-20 09:00:00+00:00',
        'recurringInterval': 'month',
        'recurringIntervalCount': 3,
    }
    now = date_time.from_string('2024-03-21 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 13

    now = date_time.from_string('2024-03-31 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 11

    now = date_time.from_string('2024-04-04 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 11

    now = date_time.from_string('2024-04-18 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, now = now)
    assert ret['subscriptionPaymentsRemaining'] == 9

def test_AddPayment():
    _mongo_mock.InitAllCollections()

    userDefault = { 'phoneNumberVerified': 1, }
    users = _stubs_data.CreateBulk(count = 10, collectionName = 'user', default = userDefault)

    weeklyEvents = [{
        'hostGroupSizeDefault': 10,
        "hostMoneyPerPersonUSD": 5,
        "priceUSD": 10,
        'archived': 0,
        'neighborhoodUName': 'testNeighborhood1',
    }]
    weeklyEvents = _stubs_data.CreateBulk(objs = weeklyEvents, collectionName = 'weeklyEvent')
    now = date_time.from_string('2024-03-20 09:00:00+00:00')
    retEvent = _event.GetNextEventFromWeekly(weeklyEvents[0]['_id'], now = now)
    event1 = retEvent['event']
    ret = mongo_db.insert_one('userMoney', {'userId': users[0]['_id'], 'balanceUSD': 0, 'creditBalanceUSD': 0,})

    # Direct payment should take revenue and NOT add to user balance.
    ret = _user_payment.AddPayment(users[0]['_id'], 10, 'event', event1['_id'], 'complete', directPayment = 1)
    assert ret['valid'] == 1
    assert ret['revenueUSD'] == 3.73
    userMoney = mongo_db.find_one('userMoney', {'userId': users[0]['_id']})['item']
    assert userMoney['balanceUSD'] == 0

    # Positive amount should increase user balance and NOT take revenue.
    ret = _user_payment.AddPayment(users[0]['_id'], 15, 'event', event1['_id'], 'complete',)
    assert ret['valid'] == 1
    assert ret['revenueUSD'] == 0
    userMoney = mongo_db.find_one('userMoney', {'userId': users[0]['_id']})['item']
    assert userMoney['balanceUSD'] == 15

    # Negative amount should reduce user balance and take revenue.
    ret = _user_payment.AddPayment(users[0]['_id'], -10, 'event', event1['_id'], 'complete',)
    assert ret['valid'] == 1
    assert ret['revenueUSD'] == 3.73
    userMoney = mongo_db.find_one('userMoney', {'userId': users[0]['_id']})['item']
    assert userMoney['balanceUSD'] == 5
