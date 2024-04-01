from common import mongo_db_crud as _mongo_db_crud
import mongo_db
from event import event as _event
from event import event_payment as _event_payment
from event import user_event as _user_event
from event import weekly_event as _weekly_event
from notifications_all import sms_twilio as _sms_twilio
from user_auth import user as _user

def Save(userWeeklyEvent: dict, now = None):
    userWeeklyEvent = _mongo_db_crud.CleanId(userWeeklyEvent)
    ret = { 'valid': 0, 'message': '', 'userWeeklyEvent': {}, 'notifyUserIdsHosts': {}, 'notifyUserIdsAttendees': {}, }

    # Confirm user has paid.
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(userWeeklyEvent['weeklyEventId'])})['item']
    retPay = _event_payment.GetSubscriptionDiscounts(weeklyEvent['priceUSD'], weeklyEvent['hostGroupSizeDefault'])
    query = { 'userId': userWeeklyEvent['userId'], 'forType': 'weeklyEvent', 'forId': weeklyEvent['_id'] }
    userPaymentSubscription = mongo_db.find_one('userPaymentSubscription', query)['item']
    if userPaymentSubscription is not None and userPaymentSubscription['status'] == 'complete':
        pricePerSpot = retPay['yearlyPrice'] if userPaymentSubscription['recurringInterval'] == 'year' else retPay['monthlyPrice']
        amountOwed = pricePerSpot * userWeeklyEvent['attendeeCountAsk']
        if abs(userPaymentSubscription['amountUSD']) < amountOwed:
            ret['valid'] = 0
            ret['message'] = 'Insufficient funds.'
            return ret
    
    ret = _mongo_db_crud.Save('userWeeklyEvent', userWeeklyEvent)

    retAdd = AddWeeklyUsersToEvent(weeklyEvent['_id'], now = now)
    ret['notifyUserIdsHosts'] = retAdd['notifyUserIdsHosts']
    ret['notifyUserIdsAttendees'] = retAdd['notifyUserIdsAttendees']

    return ret

def AddWeeklyUsersToEvent(weeklyEventId: str, now = None):
    ret = { 'valid': 1, 'message': '', 'newUserEvents': [], 'notifyUserIds': { 'sms': [], },
        'notifyUserIdsHosts': { 'sms': [], }, 'notifyUserIdsAttendees': { 'sms': [], }, }
    # Get next event, and all users signed up for this event.
    retEvent = _event.GetNextEventFromWeekly(weeklyEventId, now = now)
    query = { 'eventId': retEvent['event']['_id'] }
    userEvents = mongo_db.find('userEvent', query)['items']
    userEventsByUserId = {}
    for userEvent in userEvents:
        userEventsByUserId[userEvent['userId']] = userEvent

    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    smsInfo = {
        'body': "If you would like to host or add guests for this week's event: " + _weekly_event.GetUrl(weeklyEvent),
    }
    # Get all weekly event users and ensure they are all signed up for this week's event (sign them up if not yet).
    query = { 'weeklyEventId': weeklyEventId }
    userWeeklyEvents = mongo_db.find('userWeeklyEvent', query)['items']
    for userWeeklyEvent in userWeeklyEvents:
        userId = userWeeklyEvent['userId']
        if userId not in userEventsByUserId:
            userEvent = {
                'userId': userId,
                'eventId': retEvent['event']['_id'],
                'hostGroupSizeMax': 0,
                'attendeeCountAsk': userWeeklyEvent['attendeeCountAsk'],
            }
            retUserEvent = _user_event.Save(userEvent, 'paidSubscription')
            ret['notifyUserIdsHosts']['sms'] += retUserEvent['notifyUserIdsHosts']['sms']
            ret['notifyUserIdsAttendees']['sms'] += retUserEvent['notifyUserIdsAttendees']['sms']
            if retUserEvent['valid']:
                ret['newUserEvents'].append(retUserEvent['userEvent'])
                retPhone = _user.GetPhone(userId)
                if retPhone['valid']:
                    retSms = _sms_twilio.Send(smsInfo['body'], retPhone['phoneNumber'])
                    if retSms['valid']:
                        ret['notifyUserIds']['sms'].append(userId)
    return ret

def Get(weeklyEventId: str, userId: str, withWeeklyEvent: int = 0, withEvent: int = 0):
    query = { 'weeklyEventId': weeklyEventId, 'userId': userId, }
    ret = _mongo_db_crud.Get('userWeeklyEvent', query)
    if withWeeklyEvent:
        ret['weeklyEvent'] = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    if withEvent:
        retEvents = _event.GetNextEvents(weeklyEventId, minHoursBeforeRsvpDeadline = 0)
        ret['event'] = retEvents['thisWeekEvent']
        ret['rsvpDeadlinePassed'] = retEvents['rsvpDeadlinePassed']
        ret['nextEvent'] = retEvents['nextWeekEvent']
    return ret
