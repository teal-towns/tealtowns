import datetime
import dateutil.parser
import dateparser
import math
import pytz

def now(tz = 'UTC', microseconds = False):
    # return pytz.utc.localize(datetime.datetime.utcnow())
    dt = datetime.datetime.now(pytz.timezone(tz))
    if not microseconds:
        dt = dt.replace(microsecond = 0)
    return dt

def now_string(format = '%Y-%m-%d %H:%M:%S %z', tz = 'UTC'):
    return string(now(tz), format)

def arrayString(datetimes, format = '%Y-%m-%d %H:%M:%S %z'):
    return list(map(lambda datetime1: string(datetime1, format), datetimes))

def arrayStringFields(array1, fields=[], format = '%Y-%m-%d %H:%M:%S %z'):
    def mapString1(obj1):
        return dictStringFields(obj1, fields, format)

    return list(map(mapString1, array1))

def dictStringFields(object1, fields=[], format = '%Y-%m-%d %H:%M:%S %z'):
    newObject = {}
    for key in object1:
        if key in fields:
            newObject[key] = string(object1[key], format)
        else:
            newObject[key] = object1[key]
    return newObject

def string(datetime1, format = '%Y-%m-%d %H:%M:%S %z'):
    # return datetime1.strftime('%Y-%m-%d %H:%M:%S %z')
    # Much more performant.
    return datetime1.isoformat()

def stringFormat(datetime1, format = '%Y-%m-%d %H:%M:%S %z'):
    return datetime1.strftime('%Y-%m-%d %H:%M:%S %z')

# def from_string(datetime_string, format = '%Y-%m-%d %H:%M:%S %z'):
#     return datetime.strptime(datetime_string, format)
def from_string(dt_string):
    return dateutil.parser.parse(dt_string)

def remove_seconds(datetime1):
    return datetime1.replace(second = 0, microsecond = 0)

def remove_microseconds(datetime1):
    return datetime1.replace(microsecond = 0)

# Sets seconds (and microseconds) to 0.
def remove_seconds_string(datetime_string, format_in = '%Y-%m-%d %H:%M:%S %z', format_out = '%Y-%m-%d %H:%M:%S %z'):
    datetime1 = from_string(datetime_string)
    datetime1 = remove_seconds(datetime1)
    return string(datetime1, format_out)

def diff(datetime1, datetime2, unit='minutes'):
    if datetime2 > datetime1:
        dt_diff = datetime2 - datetime1
    else:
        dt_diff = datetime1 - datetime2
    # Note only total_seconds works - otherwise it just gives the remainer
    # (e.g. if more than one hour, time will be 1 hour and 5 seconds, not 3605 seconds).
    # https://stackoverflow.com/questions/2788871/date-difference-in-minutes-in-python
    if unit == 'seconds':
        return float(dt_diff.total_seconds())
    if unit == 'minutes':
        return float(dt_diff.total_seconds() / 60)
    elif unit == 'hours':
        return float(dt_diff.total_seconds() / (60*60))
    # Unlike seconds, apparently days will not cut off weeks and months, so this
    # still works if more than 7 days.
    elif unit == 'days':
        return float(dt_diff.days)
    return None

def to_biggest_unit(value, unit = 'minutes'):
    if unit == 'minutes':
        if value < 60:
            return {
                'value': math.floor(value),
                'unit': 'minutes'
            }
        if value < (60 * 24):
            return {
                'value': math.floor(value / 60),
                'unit': 'hours'
            }
        if value < (60 * 24 * 28):
            return {
                'value': math.floor(value / 60 / 24),
                'unit': 'days'
            }
    return None

# Note this will not handle intervals larger than the size of the
# next bigger unit (e.g. >60 minutes). So 90 minutes (1.5 hours) for example,
# could not be done with this; need whole numbers of each unit.
# E.g. turn 10:51 into 10:45 if interval is 15 minutes.
def floor_time_interval(datetime1, interval, unit = 'minutes'):
    if unit == 'seconds':
        seconds = math.floor(datetime1.second / interval) * interval
        return datetime1.replace(second = seconds, microsecond = 0)
    elif unit == 'minutes':
        minutes = math.floor(datetime1.minute / interval) * interval
        return datetime1.replace(minute = minutes, second = 0, microsecond = 0)
    elif unit == 'hours':
        hours = math.floor(datetime1.hour / interval) * interval
        return datetime1.replace(hour = hours, minute = 0, second = 0, microsecond = 0)
    elif unit == 'days':
        days = math.floor(datetime1.day / interval) * interval
        return datetime1.replace(day = days, hour = 0, minute = 0, second = 0, microsecond = 0)
    elif unit == 'months':
        months = math.floor(datetime1.month / interval) * interval
        return datetime1.replace(month = months, day = 0, hour = 0, minute = 0, second = 0, microsecond = 0)
    elif unit == 'years':
        years = math.floor(datetime1.year / interval) * interval
        return datetime1.replace(year = years, month = 0, day = 0, hour = 0, minute = 0, second = 0, microsecond = 0)
    return None

def nextMonth(datetime1, hour=0, minute=0):
    currentMonth = datetime1.month
    currentYear = datetime1.year
    if currentMonth == 12:
        nextMonth = 1
        nextYear = currentYear + 1
    else:
        nextMonth = currentMonth + 1
        nextYear = currentYear
    nextDatetime = datetime.datetime(nextYear, nextMonth, 1, hour, minute, 0, \
        tzinfo=pytz.timezone('UTC'))
    return nextDatetime

def previousMonth(datetime1, hour=0, minute=0):
    currentMonth = datetime1.month
    currentYear = datetime1.year
    if currentMonth == 1:
        previousMonth = 12
        previousYear = currentYear - 1
    else:
        previousMonth = currentMonth - 1
        previousYear = currentYear
    previousDatetime = datetime.datetime(previousYear, previousMonth, 1, hour, minute, 0, \
        tzinfo=pytz.timezone('UTC'))
    return previousDatetime

def dateToMilliseconds(date_str):
    """Convert UTC date to milliseconds
    If using offset strings add "UTC" to date string e.g. "now UTC", "11 hours ago UTC"
    See dateparse docs for formats http://dateparser.readthedocs.io/en/latest/
    :param date_str: date in readable format, i.e. "January 01, 2018", "11 hours ago UTC", "now UTC"
    :type date_str: str
    """
    # get epoch value in UTC
    epoch = datetime.datetime.utcfromtimestamp(0).replace(tzinfo=pytz.utc)
    # parse our date string
    d = dateparser.parse(date_str)
    # if the date is not timezone aware apply UTC timezone
    if d.tzinfo is None or d.tzinfo.utcoffset(d) is None:
        d = d.replace(tzinfo=pytz.utc)

    # return the difference in time
    return int((d - epoch).total_seconds() * 1000.0)

def toUTC(datetime1):
    return datetime.datetime.fromtimestamp(datetime1.timestamp(), pytz.utc)

def toUTCString(datetimeString):
    datetime1 = from_string(datetimeString)
    datetimeUTC = toUTC(datetime1)
    return string(datetimeUTC)
