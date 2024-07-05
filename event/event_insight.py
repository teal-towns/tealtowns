import date_time
import mongo_db

def AddEventView(eventId: str, now = None, withEventInsight: int = 0, userOrIP: str = ''):
    if len(userOrIP) < 0:
        # '.' is a reserved character for field names
        userOrIP = 'ip_0-0-0-0'
    now = now if now is not None else date_time.now()
    ret = { "valid": 1, "message": "", "eventInsight": {}, }
    nowString = date_time.string(now)
    query = { "eventId": eventId, }
    item = mongo_db.find_one('eventInsight', query)['item']
    if item is None:
        uniqueViewsAt = {}
        uniqueViewsAt[userOrIP] = [ nowString ]
        item = { "eventId": eventId, "uniqueViewsAt": uniqueViewsAt }
        mongo_db.insert_one('eventInsight', item)
    elif userOrIP not in item['uniqueViewsAt']:
        key = 'uniqueViewsAt.' + userOrIP
        mutation = { '$set': {} }
        mutation['$set'][key] = [ nowString ]
        mongo_db.update_one('eventInsight', query, mutation, validate = 0)
    else:
        key = 'uniqueViewsAt.' + userOrIP
        mutation = { "$push": {} }
        mutation['$push'][key] = nowString
        mongo_db.update_one('eventInsight', query, mutation, validate = 0)
    if withEventInsight:
        ret['eventInsight'] = mongo_db.find_one('eventInsight', query)['item']
    return ret

def GetByEvent(eventId: str, addEventView: int = 0, userOrIP: str = ''):
    if addEventView:
        ret = AddEventView(eventId, withEventInsight = 1, userOrIP = userOrIP)
    ret = { "valid": 1, "message": "", "eventInsight": {}, }
    ret['eventInsight'] = mongo_db.find_one('eventInsight', { "eventId": eventId })['item']
    if ret['eventInsight'] is None:
        ret['eventInsight'] = {}
    return ret
