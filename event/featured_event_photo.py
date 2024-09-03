import datetime

from common import mongo_db_crud as _mongo_db_crud
import date_time
import mongo_db

def GetRecentEventFeedbacks(daysPast: int = 30, now = None):
    ret = { 'valid': 1, 'message': '', 'eventFeedbacks': [], }
    now = now if now is not None else date_time.now()
    minDate = date_time.string(now - datetime.timedelta(days = daysPast))
    query = { 'imageUrls.0': { '$exists': 1 }, 'updatedAt': { '$gte': minDate } }
    fields = { 'eventId': 1, 'imageUrls': 1, 'updatedAt': 1, 'start': 1, 'end': 1, }
    sortObj = { 'updatedAt': -1 }
    ret['eventFeedbacks'] = mongo_db.find('eventFeedback', query, fields = fields, sort_obj = sortObj)['items']
    return ret

def CreateFeaturedEventPhoto(eventId: str, imageUrl: str):
    ret = { 'valid': 1, 'message': '', 'featuredEventPhoto': {}, }
    query = { '_id': mongo_db.to_object_id(eventId) }
    fields = { 'start': 1, 'end': 1, 'neighborhoodUName': 1, 'weeklyEventUName': 1, 'weeklyEventId': 1, }
    event = mongo_db.find_one('event', query, fields = fields)['item']
    if event is None:
        ret['valid'] = 0
        ret['message'] = 'Event not found.'
        return ret
    featuredEventPhoto = {
        'eventId': eventId,
        'imageUrl': imageUrl,
        'start': event['start'],
        'end': event['end'],
        'neighborhoodUName': event['neighborhoodUName'],
        # 'weeklyEventUName': event['weeklyEventUName'],
    }
    fields = { 'uName': 1, 'title': 1, }
    query = { '_id': mongo_db.to_object_id(event['weeklyEventId']) }
    weeklyEvent = mongo_db.find_one('weeklyEvent', query, fields = fields)['item']
    if weeklyEvent is None:
        ret['valid'] = 0
        ret['message'] = 'Weekly event not found.'
        return ret
    featuredEventPhoto['weeklyEventUName'] = weeklyEvent['uName']
    featuredEventPhoto['title'] = weeklyEvent['title']
    # First delete if any exist.
    mongo_db.delete_many('featuredEventPhoto', { 'eventId': eventId })
    ret = _mongo_db_crud.Save('featuredEventPhoto', featuredEventPhoto)
    return ret
