import math

_monthlyDiscount = 0.1
_monthly3Discount = 0.2
_yearlyDiscount = 0.2
_maxDiscount = 0.2
_payFeeFactor = 0.029 + 0.008
_payFeeFixed = 0.3
_cutFactor = 0.01

def GetSubscriptionDiscounts(weeklyPrice: float, hostGroupSize: int):
    hostGroupSize = float(hostGroupSize)
    yearlyFullPrice = weeklyPrice * 52
    monthlyFullPrice = yearlyFullPrice / 12
    monthly3FullPrice = yearlyFullPrice / 12 * 3
    yearlyPrice = math.ceil(yearlyFullPrice * (1 - _yearlyDiscount))
    monthlyPrice = math.ceil(monthlyFullPrice * (1 - _monthlyDiscount))
    monthly3Price = math.ceil(monthly3FullPrice * (1 - _monthly3Discount))
    yearlySavingsPerYear = yearlyFullPrice - yearlyPrice
    monthlySavingsPerYear = math.floor((monthlyFullPrice - monthlyPrice) * 12)
    monthly3SavingsPerYear = math.floor((monthly3FullPrice - monthly3Price) * 12 / 3)

    # minFunds = yearlyPrice
    # eventsPerPeriod = 52
    # minFunds = monthly3Price
    # eventsPerPeriod = 52 / 12 * 3
    # if (hostGroupSize > 0):
    #     minFunds = minFunds * (hostGroupSize - 1) / hostGroupSize
    # payInfo = GetPayInfo(minFunds, eventsPerPeriod)
    eventFunds = GetSingleEventFunds(weeklyPrice, hostGroupSize)

    return {
        # 'yearlyPrice': yearlyPrice, 'yearlySavingsPerYear': yearlySavingsPerYear,
        'monthlyPrice': monthlyPrice, 'monthlySavingsPerYear': monthlySavingsPerYear,
        'monthly3Price': monthly3Price, 'monthly3SavingsPerYear': monthly3SavingsPerYear,
        'eventFunds': eventFunds,
    }

def GetSingleEventFunds(price: float, hostGroupSize: int):
    payFee = price * _payFeeFactor + _payFeeFixed
    minPrice = price * (1 - _maxDiscount)
    minProfit = price * _cutFactor
    profitHostBuffer = minProfit
    if (hostGroupSize > 0):
        profitHostBuffer += (minPrice - payFee - minProfit) / (hostGroupSize - 1)
    eventFunds = math.floor(minPrice - payFee - profitHostBuffer)
    return eventFunds

# def GetPayInfo(funds: float, eventsPerPayPeriod: float = 1):
#     fundsPerEvent = funds / eventsPerPayPeriod
#     payFee = funds * _payFeeFactor + _payFeeFixed
#     payFeePerEvent = payFee / eventsPerPayPeriod
#     cutPerEvent = math.ceil(fundsPerEvent * _cutFactor)
#     eventFunds = math.floor(fundsPerEvent - payFeePerEvent - cutPerEvent)
#     return { 'eventFunds': eventFunds }

def GetRevenue(paymentUSD: float, singleEventFunds: float, recurringInterval: str = '',
    recurringIntervalCount: int = 1, quantity: int = 1, hostGroupSize: int = 0,
    fullPriceSingleEvent: float = 0):
    paymentUSD = abs(paymentUSD)
    eventsPerPayPeriod = 1
    if recurringInterval == 'month':
        eventsPerPayPeriod = 52/12 * recurringIntervalCount
    elif recurringInterval == 'year':
        eventsPerPayPeriod = 52 * recurringIntervalCount
    totalEventFunds = singleEventFunds * eventsPerPayPeriod * quantity
    payFee = paymentUSD * _payFeeFactor + _payFeeFixed
    payFee = math.ceil(payFee * 100) / 100.0
    revenue = paymentUSD - payFee - totalEventFunds
    # If host group size, we need to save money to pay for the host (future credit money, which is amount minus fees).
    if hostGroupSize > 0 and fullPriceSingleEvent > 0:
        # amountWithoutFees = GetPayInfo(fullPriceSingleEvent, 1)['eventFunds']
        amountWithoutFees = GetSingleEventFunds(fullPriceSingleEvent, hostGroupSize)
        sharePerGroupMember = amountWithoutFees / hostGroupSize
        revenue = revenue - (sharePerGroupMember * eventsPerPayPeriod * quantity)
    # Round down to 2 digits (cents)
    revenue = math.floor(revenue * 100) / 100.0
    return revenue
