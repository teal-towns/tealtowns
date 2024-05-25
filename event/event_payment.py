import math

_monthlyDiscount = 0.1
_yearlyDiscount = 0.25
_payFeeFactor = 0.029 + 0.008
_payFeeFixed = 0.3
_cutFactor = 0.01

def GetSubscriptionDiscounts(weeklyPrice: float, hostGroupSize: int):
    hostGroupSize = float(hostGroupSize)
    yearlyFullPrice = weeklyPrice * 52
    monthlyFullPrice = yearlyFullPrice / 12;
    yearlyPrice = math.ceil(yearlyFullPrice * (1 - _yearlyDiscount))
    monthlyPrice = math.ceil(monthlyFullPrice * (1 - _monthlyDiscount))
    yearlySavingsPerYear = yearlyFullPrice - yearlyPrice
    monthlySavingsPerYear = math.floor((monthlyFullPrice - monthlyPrice) * 12)

    yearlyFunds = yearlyPrice
    if (hostGroupSize > 0):
        yearlyFunds = yearlyPrice * (hostGroupSize - 1) / hostGroupSize
    eventsPerYear = 52
    payInfo = GetPayInfo(yearlyFunds, eventsPerYear)

    return { 'yearlyPrice': yearlyPrice, 'monthlyPrice': monthlyPrice,
        'yearlySavingsPerYear': yearlySavingsPerYear, 'monthlySavingsPerYear': monthlySavingsPerYear,
        'eventFunds': payInfo['eventFunds'] }

def GetPayInfo(funds: float, eventsPerPayPeriod: float = 1):
    fundsPerEvent = funds / eventsPerPayPeriod
    payFee = funds * _payFeeFactor + _payFeeFixed
    payFeePerEvent = payFee / eventsPerPayPeriod
    cutPerEvent = math.ceil(fundsPerEvent * _cutFactor)
    eventFunds = math.floor(fundsPerEvent - payFeePerEvent - cutPerEvent)
    return { 'eventFunds': eventFunds }
