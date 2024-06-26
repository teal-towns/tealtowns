import date_time
from user_payment import user_payment as _user_payment

def test_GetSubscriptionPaymentsRemaining():
    userPaymentSubscription = {
        'createdAt': '2024-03-20 09:00:00+00:00',
        'recurringInterval': 'month',
    }
    now = date_time.from_string('2024-03-21 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, '2024-03-20 09:00:00+00:00', now = now)
    assert ret['subscriptionPaymentsRemaining'] == 4

    now = date_time.from_string('2024-03-31 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, '2024-03-27 09:00:00+00:00', now = now)
    assert ret['subscriptionPaymentsRemaining'] == 3

    now = date_time.from_string('2024-04-04 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, '2024-04-03 09:00:00+00:00', now = now)
    assert ret['subscriptionPaymentsRemaining'] == 2

    now = date_time.from_string('2024-04-18 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, '2024-04-17 09:00:00+00:00', now = now)
    assert ret['subscriptionPaymentsRemaining'] == 0

    userPaymentSubscription = {
        'createdAt': '2024-03-20 09:00:00+00:00',
        'recurringInterval': 'year',
    }
    now = date_time.from_string('2024-03-21 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, '2024-03-20 09:00:00+00:00', now = now)
    assert ret['subscriptionPaymentsRemaining'] == 52

    now = date_time.from_string('2024-04-21 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, '2024-04-17 09:00:00+00:00', now = now)
    assert ret['subscriptionPaymentsRemaining'] == 47

    now = date_time.from_string('2024-01-02 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, '2024-01-01 09:00:00+00:00', now = now)
    assert ret['subscriptionPaymentsRemaining'] == 11

    # Next year
    now = date_time.from_string('2025-05-02 09:00:00+00:00')
    ret = _user_payment.GetSubscriptionPaymentsRemaining(userPaymentSubscription, '2025-05-01 09:00:00+00:00', now = now)
    assert ret['subscriptionPaymentsRemaining'] == 46
