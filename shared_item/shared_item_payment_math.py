import math

_resaleDiscount = 0.5
_maintenancePerYearFactor = 0.02
_maintenancePerPersonPerYearMin = 5
_investmentReturnPerYearFactor = 0.1
_payFeeFactor = 0.029 + 0.008
_payFeeFixed = 0.3
_cutFactor = 0.01
_lowFeeAmount = 300
_downPerPersonMinFactor = 0.05
_downTotalFactor = 0.33
_downPerPersonMax = 10000
_downPerPersonMin = 100
_minDiscountFactor = 0.1
_minDiscountPrice = 10000
_minMonthlyPayment = 10

# def MaxCurrentPrice(originalPrice: float, generation: int):
#     if (generation <= 1):
#         return originalPrice
#     min1 = min(_minDiscountPrice, originalPrice * _minDiscountFactor)
#     return max(min1, originalPrice * pow(_resaleDiscount, (generation - 1)))

# def GetMaintenancePerYear(currentPrice: float, numOwners: int):
#     return max(currentPrice * _maintenancePerYearFactor, _maintenancePerPersonPerYearMin * numOwners)

def GetPayments(currentPrice: float, monthsToPayBack: int, numOwners: int,
    maintenancePerYear: float):
    returnPerMonthFactor = _investmentReturnPerYearFactor / 12
    investorProfit = currentPrice * returnPerMonthFactor * monthsToPayBack
    totalToPayBack = currentPrice + investorProfit
    maintenancePerPersonMonthly = maintenancePerYear / 12 / numOwners
    monthlyPaymentMin = ((totalToPayBack / numOwners / monthsToPayBack) + maintenancePerPersonMonthly)

    min1 = min(totalToPayBack / numOwners, _downPerPersonMin)
    min2 = min(totalToPayBack * _downPerPersonMinFactor, totalToPayBack * _downTotalFactor / numOwners)
    min2 = min(min2, _downPerPersonMax)
    downPerPerson = max(monthlyPaymentMin, min1)
    downPerPerson = max(downPerPerson, min2)

    basePerPerson = totalToPayBack / numOwners - downPerPerson
    monthlyPayment = ((basePerPerson / monthsToPayBack) + maintenancePerPersonMonthly)
    if (monthlyPayment < _minMonthlyPayment):
        if (basePerPerson <= 0):
            monthlyPayment = 0
            monthsToPayBack = 0
        elif (basePerPerson < _minMonthlyPayment * 1.5):
            monthlyPayment = basePerPerson
            monthsToPayBack = 1
        else:
            monthlyPayment = _minMonthlyPayment
            monthsToPayBack = math.ceil(basePerPerson / monthlyPayment - maintenancePerPersonMonthly)

    totalPerPerson = math.ceil(downPerPerson) + math.ceil(monthlyPayment) * monthsToPayBack
    return {
      'monthlyPayment': math.ceil(monthlyPayment),
      'monthlyPaymentWithFee': AddFee(monthlyPayment),
      'downPerPerson': math.ceil(downPerPerson),
      'downPerPersonWithFee': AddFee(downPerPerson),
      'investorProfit': math.floor(investorProfit),
      'monthsToPayBack': monthsToPayBack,
      'totalPerPerson': totalPerPerson,
      'totalToPayBack': math.floor(totalToPayBack),
    }

def AddFee(amount: float, withCut: bool = True, withPayFee: bool = True):
    if amount <= 0:
        return 0
    cut = GetCut(amount) if withCut else 0
    payFee = 0
    if withPayFee:
        payFee = GetFee(amount)
    withFee = math.ceil(amount + cut + payFee)
    return withFee

def GetFee(amount: float):
    amount = abs(amount)
    payFee = math.ceil(amount * _payFeeFactor + _payFeeFixed)
    if amount < _lowFeeAmount and amount >= 1:
        payFee += 1
    return payFee

def GetCut(amount: float):
    if amount < 0:
        return -1 * math.ceil(abs(amount) * _cutFactor)
    return math.ceil(amount * _cutFactor)

def GetRevenue(amount: float):
    amount = abs(amount)
    revenue = GetCut(amount)
    # Add any fee cents (due to rounding).
    payFee = GetFee(amount)
    payFeeActual = amount * _payFeeFactor + _payFeeFixed
    revenue += payFee - payFeeActual
    # Round down to 2 digits (cents)
    revenue = math.floor(revenue * 100) / 100.0
    return revenue

def RemoveFee(amount: float, withCut: bool = True, withPayFee: bool = True):
    if amount <= 1:
        return amount
    # Must get original amount first, using ALL fees.
    totalFactor = _cutFactor + _payFeeFactor
    original = amount
    if amount < _lowFeeAmount:
        original -= 1
    original = math.floor(original / (1 + totalFactor))

    cut = GetCut(original) if withCut else 0
    payFee = math.ceil(original * _payFeeFactor + _payFeeFixed) if withPayFee else 0
    if withPayFee and amount < _lowFeeAmount:
        payFee += 1
    return math.floor(amount - cut - payFee)
