from event import event_payment as _event_payment

def test_GetSubscriptionDiscounts():
    ret = { 'monthlyPrice': 39.0, 'monthlySavingsPerYear': 52.0,
        'monthly3Price': 104.0, 'monthly3SavingsPerYear': 104.0,
        'eventFunds': 5.0 }
    assert _event_payment.GetSubscriptionDiscounts(10, 10) == ret

    ret = { 'monthlyPrice': 67.0, 'monthlySavingsPerYear': 80.0,
        'monthly3Price': 177.0, 'monthly3SavingsPerYear': 176.0,
        'eventFunds': 10.0 }
    assert _event_payment.GetSubscriptionDiscounts(17, 10) == ret

    # If no hosts, more money per event (but same prices).
    ret = { 'monthlyPrice': 39.0, 'monthlySavingsPerYear': 52.0,
        'monthly3Price': 104.0, 'monthly3SavingsPerYear': 104.0,
        'eventFunds': 6.0 }
    assert _event_payment.GetSubscriptionDiscounts(10, 0) == ret

    # If no hosts, can charge less to get same event funds.
    ret = { 'monthlyPrice': 36.0, 'monthlySavingsPerYear': 36.0,
        'monthly3Price': 94.0, 'monthly3SavingsPerYear': 92.0,
        'eventFunds': 5.0 }
    assert _event_payment.GetSubscriptionDiscounts(9, 0) == ret

def test_GetPayInfo():
    ret = { 'eventFunds': 8.0 }
    assert _event_payment.GetPayInfo(10, 1) == ret

    ret = { 'eventFunds': 95 }
    assert _event_payment.GetPayInfo(100, 1) == ret

    ret = { 'eventFunds': 6 }
    assert _event_payment.GetPayInfo(390, 52) == ret

    ret = { 'eventFunds': 17 }
    assert _event_payment.GetPayInfo(1000, 52) == ret

    ret = { 'eventFunds': 183 }
    assert _event_payment.GetPayInfo(10000, 52) == ret

def test_GetRevenue():
    assert _event_payment.GetRevenue(39, 5, 'month', quantity = 1) == 15.58
    assert _event_payment.GetRevenue(39 * 2, 5, 'month', quantity = 2) == 31.47
    assert _event_payment.GetRevenue(390, 5, 'year', quantity = 1) == 115.26
    assert _event_payment.GetRevenue(390 * 3, 5, 'year', quantity = 3) == 346.41
