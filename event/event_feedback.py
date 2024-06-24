import datetime
import threading
import time

import date_time
import log
import ml_config
import mongo_db
from common import mongo_db_crud as _mongo_db_crud
from event import event as _event
from event import user_event as _user_event

_config = ml_config.get_config()

def GetByEvent(eventId: str, autoCreate: int = 1, notificationSent: int = 0, withUserFeedback: int = 0,
    withEvent: int = 0,):
    ret = { "valid": 1, "message": "", 'userFeedbacks': [], }
    ret['eventFeedback'] = mongo_db.find_one('eventFeedback', { "eventId": eventId })['item']
    if ret['eventFeedback'] is None and autoCreate:
        eventFeedback = { "eventId": eventId, "feedbackVotes": [], "positiveVotes": [],
            "notificationSent": notificationSent, }
        ret = _mongo_db_crud.Save('eventFeedback', eventFeedback)
    if ret['eventFeedback'] is None:
        ret['valid'] = 0
        ret['message'] = 'No feedback found for event ' + eventId
        ret['eventFeedback'] = {}
    else:
        if withUserFeedback:
            query = { 'forType': 'event', 'forId': eventId }
            ret['userFeedbacks'] = mongo_db.find('userFeedback', query)['items']
        if withEvent:
            ret['event'] = mongo_db.find_one('event', { "_id": mongo_db.to_object_id(eventId) })['item']

    return ret

def AddFeedbackVote(eventFeedbackId: str, feedbackVote: dict):
    ret = { "valid": 1, "message": "", }
    query = { "_id": mongo_db.to_object_id(eventFeedbackId) }
    if 'id' not in feedbackVote:
        feedbackVote['id'] = mongo_db.newObjectIdString()
    if 'userIds' not in feedbackVote:
        feedbackVote['userIds'] = []
    ret['feedbackVote'] = feedbackVote
    mutation = { "$push": { "feedbackVotes": feedbackVote } }
    mongo_db.update_one('eventFeedback', query, mutation)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def AddPositiveVote(eventFeedbackId: str, positiveVote: dict):
    ret = { "valid": 1, "message": "", }
    query = { "_id": mongo_db.to_object_id(eventFeedbackId) }
    if 'id' not in positiveVote:
        positiveVote['id'] = mongo_db.newObjectIdString()
    if 'userIds' not in positiveVote:
        positiveVote['userIds'] = []
    ret['positiveVote'] = positiveVote
    mutation = { "$push": { "positiveVotes": positiveVote } }
    mongo_db.update_one('eventFeedback', query, mutation)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def AddUserFeedbackVote(eventFeedbackId: str, userId: str, feedbackVoteId: str):
    ret = { "valid": 1, "message": "" }
    query = { "_id": mongo_db.to_object_id(eventFeedbackId),
        "feedbackVotes": { "$elemMatch": { "id": feedbackVoteId } } }
    # addToSet avoids duplicates (push does not, so could have duplicates).
    mutation = { "$addToSet": { "feedbackVotes.$.userIds": userId } }
    mongo_db.update_one('eventFeedback', query, mutation)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def AddUserPositiveVote(eventFeedbackId: str, userId: str, positiveVoteId: str):
    ret = { "valid": 1, "message": "" }
    query = { "_id": mongo_db.to_object_id(eventFeedbackId),
        "positiveVotes": { "$elemMatch": { "id": positiveVoteId } } }
    # addToSet avoids duplicates (push does not, so could have duplicates).
    mutation = { "$addToSet": { "positiveVotes.$.userIds": userId } }
    mongo_db.update_one('eventFeedback', query, mutation)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def AddUserFeedbackVotes(eventFeedbackId: str, userId: str, feedbackVoteIds: list = [],
    positiveVoteIds: list = []):
    ret = { "valid": 1, "message": "" }
    for feedbackVoteId in feedbackVoteIds:
        AddUserFeedbackVote(eventFeedbackId, userId, feedbackVoteId)
    for positiveVoteId in positiveVoteIds:
        AddUserPositiveVote(eventFeedbackId, userId, positiveVoteId)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def RemoveFeedbackUserVote(eventFeedbackId: str, feedbackVoteId: str, userId: str):
    ret = { "valid": 1, "message": "" }
    query = { "_id": mongo_db.to_object_id(eventFeedbackId),
        "feedbackVotes": { "$elemMatch": { "id": feedbackVoteId } } }
    mutation = { "$pull": { "feedbackVotes.$.userIds": userId } }
    mongo_db.update_one('eventFeedback', query, mutation)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def RemoveFeedbackUserVotes(eventFeedbackId: str, feedbackVoteIds: list, userId: str):
    ret = { "valid": 1, "message": "" }
    for feedbackVoteId in feedbackVoteIds:
        RemoveFeedbackUserVote(eventFeedbackId, feedbackVoteId, userId)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def RemovePositiveUserVote(eventFeedbackId: str, positiveVoteId: str, userId: str):
    ret = { "valid": 1, "message": "" }
    query = { "_id": mongo_db.to_object_id(eventFeedbackId),
        "positiveVotes": { "$elemMatch": { "id": positiveVoteId } } }
    mutation = { "$pull": { "positiveVotes.$.userIds": userId } }
    mongo_db.update_one('eventFeedback', query, mutation)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def RemovePositiveUserVotes(eventFeedbackId: str, positiveVoteIds: list, userId: str):
    ret = { "valid": 1, "message": "" }
    for positiveVoteId in positiveVoteIds:
        RemovePositiveUserVote(eventFeedbackId, positiveVoteId, userId)
    ret['eventFeedback'] = GetEventFeedback(eventFeedbackId)
    return ret

def GetEventFeedback(eventFeedbackId: str):
    return mongo_db.find_one('eventFeedback', { "_id": mongo_db.to_object_id(eventFeedbackId) })['item']

def GetByWeeklyEvent(weeklyEventId: str, withUserFeedback: int = 0):
    ret = { "valid": 1, "message": "", 'eventFeedback': {}, 'userFeedbacks': [] }
    retPastEvent = _event.GetMostRecentPastEvent(weeklyEventId)
    if '_id' in retPastEvent['event']:
        retFeedback = GetByEvent(retPastEvent['event']['_id'], withUserFeedback = withUserFeedback, autoCreate = 0)
        ret['eventFeedback'] = retFeedback['eventFeedback']
        ret['event'] = retPastEvent['event']
        if withUserFeedback:
            ret['userFeedbacks'] = retFeedback['userFeedbacks']
    return ret

def CheckAndCreateForEndingEvents(now = None, endMinutesBuffer: int = 10, afterEndMinutes: int = 20):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 1, 'message': '', 'newFeedbackEventIds': [], 'notifyByEvent': {}, }
    minDate = date_time.string(now - datetime.timedelta(minutes = endMinutesBuffer))
    maxDate = date_time.string(now + datetime.timedelta(minutes = afterEndMinutes))
    query = { 'end': { '$gte': minDate, '$lte': maxDate } }
    fields = { '_id': 1 }
    events = mongo_db.find('event', query, fields = fields)['items']
    eventIds = [ event['_id'] for event in events ]
    query = { 'eventId': { '$in': eventIds } }
    fields = { '_id': 1, 'eventId': 1, 'notificationSent': 1, }
    eventFeedbacksExisting = mongo_db.find('eventFeedback', query, fields = fields)['items']
    eventIdsDoneMap = {}
    eventFeedbackByEventId = {}
    for eventFeedback in eventFeedbacksExisting:
        if 'notificationSent' in eventFeedback and eventFeedback['notificationSent'] == 1:
            eventIdsDoneMap[eventFeedback['eventId']] = 1
        else:
            eventFeedbackByEventId[eventFeedback['eventId']] = eventFeedback
    for event in events:
        if event['_id'] not in eventIdsDoneMap:
            # Send notification to get feedback.
            smsContent = 'Thanks for attending! What did you think of this event? ' + GetUrl(event['_id'])
            retNotify = _user_event.NotifyUsers(event['_id'], smsContent, minAttendeeCount = 1)
            ret['notifyByEvent'][event['_id']] = { 'notifyUserIds': retNotify['notifyUserIds'] }
            eventFeedback = { "eventId": event['_id'], "feedbackVotes": [], "positiveVotes": [],
                "notificationSent": 1, }
            if event['_id'] in eventFeedbackByEventId:
                eventFeedback['_id'] = eventFeedbackByEventId[event['_id']]['_id']
            retOne = _mongo_db_crud.Save('eventFeedback', eventFeedback)
            ret['newFeedbackEventIds'].append(event['_id'])
    return ret

def GetUrl(eventId: str):
    return _config['web_server']['urls']['base'] + '/event-feedback-save?eventId=' + str(eventId)

def CheckEventFeedbackLoop(timeoutMinutes = 15):
    log.log('info', 'event_feedback.CheckEventFeedbackLoop starting')
    thread = None
    while 1:
        if thread is None or not thread.is_alive():
            thread = threading.Thread(target=CheckAndCreateForEndingEvents, args=())
            thread.start()
        time.sleep(timeoutMinutes * 60)
    return None
