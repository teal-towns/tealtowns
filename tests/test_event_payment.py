from event import event_payment as _event_payment

def test_GetSubscriptionDiscounts():
    ret = { 'monthlyPrice': 39.0, 'monthlySavingsPerYear': 52.0,
        'monthly3Price': 104.0, 'monthly3SavingsPerYear': 104.0,
        'eventFunds': 6.0 }
    assert _event_payment.GetSubscriptionDiscounts(10, 10) == ret

    ret = { 'monthlyPrice': 67.0, 'monthlySavingsPerYear': 80.0,
        'monthly3Price': 177.0, 'monthly3SavingsPerYear': 176.0,
        'eventFunds': 11.0 }
    assert _event_payment.GetSubscriptionDiscounts(17, 10) == ret

    # If no hosts, more money per event (but same prices).
    ret = { 'monthlyPrice': 39.0, 'monthlySavingsPerYear': 52.0,
        'monthly3Price': 104.0, 'monthly3SavingsPerYear': 104.0,
        'eventFunds': 7.0 }
    assert _event_payment.GetSubscriptionDiscounts(10, 0) == ret

    # If no hosts, can charge less to get same event funds.
    ret = { 'monthlyPrice': 36.0, 'monthlySavingsPerYear': 36.0,
        'monthly3Price': 94.0, 'monthly3SavingsPerYear': 92.0,
        'eventFunds': 6.0 }
    assert _event_payment.GetSubscriptionDiscounts(9, 0) == ret

def test_GetSingleEventFunds():
    assert _event_payment.GetSingleEventFunds(10, 10) == 6.0

    assert _event_payment.GetSingleEventFunds(100, 10) == 66.0

    assert _event_payment.GetSingleEventFunds(8, 10) == 5.0

    assert _event_payment.GetSingleEventFunds(8, 0) == 5.0

    assert _event_payment.GetSingleEventFunds(10, 0) == 7.0

    assert _event_payment.GetSingleEventFunds(100, 0) == 75.0

    assert _event_payment.GetSingleEventFunds(1000, 10) == 669.0
    assert _event_payment.GetSingleEventFunds(1000, 0) == 752.0

def test_GetRevenue():
    assert _event_payment.GetRevenue(8, 5, hostGroupSize = 0, fullPriceSingleEvent = 8) == 2.4
    assert _event_payment.GetRevenue(8, 5, hostGroupSize = 10, fullPriceSingleEvent = 8) == 1.9
    assert _event_payment.GetRevenue(10, 5, hostGroupSize = 0, fullPriceSingleEvent = 10) == 4.33
    assert _event_payment.GetRevenue(10, 5, hostGroupSize = 10, fullPriceSingleEvent = 10) == 3.73
    assert _event_payment.GetRevenue(9, 5, hostGroupSize = 10, fullPriceSingleEvent = 10) == 2.75
    assert _event_payment.GetRevenue(8, 5, hostGroupSize = 10, fullPriceSingleEvent = 10) == 1.80
    assert _event_payment.GetRevenue(10, 6) == 3.33
    assert _event_payment.GetRevenue(39, 5, 'month', quantity = 1) == 15.58
    assert _event_payment.GetRevenue(39, 5, 'month', quantity = 1, hostGroupSize = 10, fullPriceSingleEvent = 10) == 12.98
    assert _event_payment.GetRevenue(39 * 2, 5, 'month', quantity = 2) == 31.47
    assert _event_payment.GetRevenue(39 * 2, 5, 'month', quantity = 2, hostGroupSize = 10, fullPriceSingleEvent = 10) == 26.27

    assert _event_payment.GetRevenue(104, 5, 'month', 3, quantity = 1) == 34.84
    assert _event_payment.GetRevenue(104, 5, 'month', 3, quantity = 1, hostGroupSize = 10, fullPriceSingleEvent = 10) == 27.04
    assert _event_payment.GetRevenue(104 * 2, 5, 'month', 3, quantity = 2) == 70.00
    assert _event_payment.GetRevenue(104 * 2, 5, 'month', 3, quantity = 2, hostGroupSize = 10, fullPriceSingleEvent = 10) == 54.4

    assert _event_payment.GetRevenue(390, 5, 'year', quantity = 1) == 115.26
    assert _event_payment.GetRevenue(390, 5, 'year', quantity = 1, hostGroupSize = 10, fullPriceSingleEvent = 10) == 84.05
    assert _event_payment.GetRevenue(390 * 3, 5, 'year', quantity = 3) == 346.41
    assert _event_payment.GetRevenue(390 * 3, 5, 'year', quantity = 3, hostGroupSize = 10, fullPriceSingleEvent = 10) == 252.81
