import threading
import time

import date_time
import log
import mongo_db
from neighborhood import neighborhood as _neighborhood

def ComputeNeighborhoodStats(uName: str, now = None, withPrevious: bool = True):
    now = now if now is not None else date_time.now()
    ret = { "valid": 1, "message": "", "neighborhoodStats": {}, 'previousNeighborhoodStats': {}, }
    thisMonth = date_time.create(now.year, now.month, 1, 0, 0)
    # If 1st of the month, compute for last month.
    if now.day == 1:
        thisMonth = date_time.previousMonth(thisMonth)
    start = date_time.string(thisMonth)
    nextMonth = date_time.nextMonth(thisMonth)
    end = date_time.string(nextMonth)
    # See if already computed.
    query = { 'neighborhoodUName': uName, 'start': start, 'end': end }
    ret['neighborhoodStats'] = mongo_db.find_one('neighborhoodStatsMonthlyCache', query)['item']
    if ret['neighborhoodStats'] is None:
        retOne = _neighborhood.GetByUName(uName, withUniqueEventUsersCount = 1, withUsersCount = 1,
            minDateString = start, maxDateString = end, limitCount = 10000, withFreePaidStats = True)
        neighborhoodStats = {
            'neighborhoodUName': uName,
            'start': start,
            'end': end,
            'usersCount': retOne['usersCount'],
            'weeklyEventsCount': retOne['weeklyEventsCount'],
            'uniqueEventUsersCount': retOne['uniqueEventUsersCount'],
            'eventInfos': retOne['eventInfos'],
            'freeEventsCount': retOne['freeEventsCount'],
            'paidEventsCount': retOne['paidEventsCount'],
            'totalEventUsersCount': retOne['totalEventUsersCount'],
            'totalFreeEventUsersCount': retOne['totalFreeEventUsersCount'],
            'totalPaidEventUsersCount': retOne['totalPaidEventUsersCount'],
            'totalCutUSD': retOne['totalCutUSD'],
        }
        retInsert = mongo_db.insert_one('neighborhoodStatsMonthlyCache', neighborhoodStats)
        ret['neighborhoodStats'] = retInsert['item']

    # If not a new month, get past month to compare.
    if withPrevious and now.day != 1:
        previousStart = date_time.string(date_time.previousMonth(thisMonth))
        previousEnd = date_time.string(date_time.previousMonth(nextMonth))
        query = { 'neighborhoodUName': uName, 'start': previousStart, 'end': previousEnd }
        ret['previousNeighborhoodStats'] = mongo_db.find_one('neighborhoodStatsMonthlyCache', query)['item']
        if ret['previousNeighborhoodStats'] is None:
            ret['previousNeighborhoodStats'] = {}

    return ret

def ComputeAllNeighborhoods():
    neighborhoods = mongo_db.find('neighborhood', {}, fields = { 'uName': 1,})['items']
    for neighborhood in neighborhoods:
        ComputeNeighborhoodStats(neighborhood['uName'], withPrevious = False)

def ComputeNeighborhoodStatsLoop(timeoutMinutes = 60 * 24):
    log.log('info', 'neighborhood_stats.CheckNeighborhoodStatsLoop starting')
    thread = None
    while 1:
        if thread is None or not thread.is_alive():
            thread = threading.Thread(target=ComputeAllNeighborhoods, args=())
            thread.start()
        time.sleep(timeoutMinutes * 60)
    return None
