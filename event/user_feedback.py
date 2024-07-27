import datetime
import re

import date_time
import mongo_db
from common import mongo_db_crud as _mongo_db_crud
from event import weekly_event as _weekly_event
from notifications_all import sms_twilio as _sms_twilio
from notifications_all import email_sendgrid as _email_sendgrid

def Save(userFeedback: dict, withCheckAskForFeedback: int = 0, withCheckNeighborhoodAmbassador: int = 0,
    neighborhoodUName: str = '') -> dict:
    userFeedback = _mongo_db_crud.CleanId(userFeedback)
    if '_id' not in userFeedback and 'username' not in userFeedback:
        user = mongo_db.find_one('user', {'_id': mongo_db.to_object_id(userFeedback['userId'])})['item']
        userFeedback['username'] = user['username']
    ret = _mongo_db_crud.Save('userFeedback', userFeedback)
    ret['smsAttemptCount'] = 0
    ret['emailAttemptCount'] = 0
    if userFeedback['forType'] == 'event' and len(userFeedback['invites']) > 0:
        query = { '_id': mongo_db.to_object_id(userFeedback['forId']) }
        fields = { 'weeklyEventId': 1}
        event = mongo_db.find_one('event', query, fields = fields)['item']
        fields = { 'uName': 1 }
        query = { '_id': mongo_db.to_object_id(event['weeklyEventId']) }
        weeklyEvent = mongo_db.find_one('weeklyEvent', query, fields = fields)['item']
        retInvite = _weekly_event.SendInvites(userFeedback['invites'], weeklyEvent['uName'], userFeedback['userId'])
        ret['smsAttemptCount'] = retInvite['smsAttemptCount']
        ret['emailAttemptCount'] = retInvite['emailAttemptCount']
    if withCheckAskForFeedback:
        ret1 = CheckAskForFeedback(userFeedback['userId'], userFeedback['forId'])
        ret['missingFeedbackEventIds'] = ret1['missingFeedbackEventIds']
    if withCheckNeighborhoodAmbassador and len(neighborhoodUName) > 0:
        ret['isAlreadyAmbassador'] = 0
        ret['neighborhoodUName'] = neighborhoodUName
        query = { 'userId': userFeedback['userId'], 'neighborhoodUName': neighborhoodUName }
        item = mongo_db.find_one('userNeighborhood', query)['item']
        if item is not None and 'ambassador' in item['roles']:
            ret['isAlreadyAmbassador'] = 1

    return ret

def CheckAskForFeedback(userId: str, eventId: str = '', daysPast: int = 12, now = None,
    endMinutesBuffer: int = 10):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 1, 'message': '', 'missingFeedbackEventIds': [] }
    minDate = date_time.string(now - datetime.timedelta(days = daysPast))
    minEnd = date_time.string(now + datetime.timedelta(minutes = endMinutesBuffer))

    # If only checking 1 specific event, just check it directly and return.
    if len(eventId) > 0:
        query = { 'userId': userId, 'forType': 'event', 'forId': eventId, }
        userFeedback = mongo_db.find_one('userFeedback', query)['item']
        if userFeedback is None:
            # Ensure event is (almost) over.
            event = mongo_db.find_one('event', { '_id': mongo_db.to_object_id(eventId) })['item']
            if event['end'] <= minEnd:
                ret['missingFeedbackEventIds'].append(eventId)
        return ret

    query = { 'userId': userId, 'forType': 'event', 'updatedAt': { '$gte': minDate } }
    userFeedbacks = mongo_db.find('userFeedback', query)['items']
    eventIdsSkip = []
    for userFeedback in userFeedbacks:
        eventIdsSkip.append(userFeedback['forId'])
    query = { 'userId': userId, 'eventEnd': { '$gte': minDate, '$lte': minEnd },
        'attendeeCount': { '$gte': 1 }, 'eventId': { '$nin': eventIdsSkip } }
    fields = { 'eventId': 1 }
    userEvents = mongo_db.find('userEvent', query, fields = fields)['items']
    for userEvent in userEvents:
        ret['missingFeedbackEventIds'].append(userEvent['eventId'])
    return ret
