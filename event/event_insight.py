import date_time
import mongo_db

def AddEventView(eventId: str, now = None, withEventInsight: int = 0):
    now = now if now is not None else date_time.now()
    ret = { "valid": 1, "message": "", "eventInsight": {}, }
    nowString = date_time.string(now)
    query = { "eventId": eventId, }
    item = mongo_db.find_one('eventInsight', query)['item']
    if item is None:
        item = { "eventId": eventId, "viewsAt": [ nowString ] }
        mongo_db.insert_one('eventInsight', item)
    else:
        mutation = { "$push": { "viewsAt": nowString } }
        mongo_db.update_one('eventInsight', query, mutation)
    if withEventInsight:
        ret['eventInsight'] = mongo_db.find_one('eventInsight', query)['item']
    return ret

def GetByEvent(eventId: str, addEventView: int = 0):
    if addEventView:
        ret = AddEventView(eventId, withEventInsight = 1)
    ret = { "valid": 1, "message": "", "eventInsight": {}, }
    ret['eventInsight'] = mongo_db.find_one('eventInsight', { "eventId": eventId })['item']
    return ret
