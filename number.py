# Decimal is causing rounding errors? E.g. 1/3 is 3.333333333334 and 1/3 of 30 is 9.9999999999990
# We want to keep precision at a max, but don't increase precision for numbers that start as less.
# For example, change 33.33333333333334 to 33.33333333 and keep 1 as 1 (not 1.0000000001)

from decimal import *

# decimals = 8

# def set_decimals(decimals1):
#     global decimals
#     decimals = decimals1

# def precision_string(decimals):
#     if decimals == 0:
#         return '1'
#     precision = '.'
#     # -1 because add a '1' at the end as last digit
#     for count in range(0, (decimals-1)):
#         precision += '0'
#     precision += '1'
#     return precision

# def number(num, decimals1 = False):
#     global decimals
#     num_decimals_max = decimals1 or decimals
#     num_str = str(num)
#     index_dot = num_str.find('.')
#     if index_dot < 0:
#         num_decimals = 0
#     else:
#         num_decimals_str = len(num_str) - (index_dot + 1)
#         if num_decimals_str < num_decimals_max:
#             num_decimals = num_decimals_str
#         else:
#             num_decimals = num_decimals_max
#     precision = precision_string(num_decimals)
#     return Decimal(num).quantize(Decimal(precision), rounding=ROUND_HALF_UP)

# decimal type does not store in MongoDB
def number(num):
    if not isinstance(num, float):
        return float(num)
    return num

def toFixed(num, precision1='.01'):
    numFixed = precision(num, precision1)
    numNoZeroes = removeZeroes(str(numFixed))
    if numNoZeroes[-1] == '.':
        return str(num)
    return numNoZeroes

# '0.010000' will return a precision of 6 decimals, instead of 2! So fix by
# removing any trailing zeroes.
def removeZeroes(str1):
    newStr = str1
    lastIndex = len(str1)
    for index, char in reversed(list(enumerate(str1))):
        if char != '0':
            break
        lastIndex = index
    newStr = str1[slice(0, lastIndex)]
    return newStr

def decimalCount(numString):
    index = numString.find('.')
    if index > -1:
        return len(numString) - index - 1
    return -1

def precision(num, precision1 = '.01', round1='down'):
    precision = removeZeroes(precision1)
    # See if value is already correct precision.
    if decimalCount(str(num)) == decimalCount(precision):
        return num

    rounding = ROUND_UP if round1 == 'up' else ROUND_DOWN
    newVal = float(Decimal(num).quantize(Decimal(precision), rounding=rounding))
    if newVal == 0.0:
        newVal = float(Decimal(num).quantize(Decimal(precision), rounding=ROUND_UP))
    return newVal
