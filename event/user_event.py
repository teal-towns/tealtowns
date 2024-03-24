import copy
import math

import lodash
import mongo_db
from common import mongo_db_crud as _mongo_db_crud
from user_payment import user_payment as _user_payment

def Save(userEvent: dict, payType: str):
    ret = { 'valid': 1, 'message': '', 'userEvent': {}, 'spotsPaidFor': 0, 'availableUSD': 0, 'availableCredits': 0, }

    userEventExisting = None
    if '_id' in userEvent:
        userEventExisting = mongo_db.find_one('userEvent', {'_id': mongo_db.to_object_id(userEvent['_id'])})['item']
    if userEventExisting:
        # Do not allow changing host group size if complete.
        if userEventExisting['hostStatus'] == 'complete' and userEventExisting['hostGroupSize'] > 0:
            userEvent['hostGroupSize'] = userEventExisting['hostGroupSize']
            userEvent['hostStatus'] = userEventExisting['hostStatus']
        # Do not allow reducing attendee count ask.
        if userEvent['attendeeCountAsk'] < userEventExisting['attendeeCountAsk']:
            userEvent['attendeeCountAsk'] = userEventExisting['attendeeCountAsk']
        # If increase attendee count, reset status to pending.
        elif userEvent['attendeeCountAsk'] >= userEventExisting['attendeeCountAsk']:
            userEvent['attendeeStatus'] = 'pending'
        userEvent = lodash.extend_object(userEventExisting, userEvent)
    else:
        event = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(userEvent['eventId'])})['item']
        weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(event['weeklyEventId'])})['item']
        if 'hostGroupSizeMax' not in userEvent:
            userEvent['hostGroupSizeMax'] = 0
        userEvent = lodash.extend_object({
            'hostStatus': 'pending' if userEvent['hostGroupSizeMax'] > 0 else 'complete',
            'hostGroupSize': 0,
            'attendeeStatus': 'pending',
            'attendeeCount': 0,
            'creditsEarned': 0,
            'creditsRedeemed': 0,
            'creditsPriceUSD': weeklyEvent['priceUSD'],
        }, userEvent)

    retPay = CheckAndTakePayment(userEvent['userId'], userEvent['eventId'], userEvent['attendeeCountAsk'], payType)
    if not retPay['valid']:
        return retPay
    userEvent['creditsRedeemed'] = retPay['creditsRedeemed']

    ret = _mongo_db_crud.Save('userEvent', userEvent)
    ret['spotsPaidFor'] = retPay['spotsPaidFor']
    ret['availableUSD'] = retPay['availableUSD']
    ret['availableCredits'] = retPay['availableCredits']

    retCheck = CheckAddHostsAndAttendees(userEvent['eventId'])
    # If updated, re-get event to return.
    if userEvent['userId'] in retCheck['userIdsUpdated']:
        ret['userEvent'] = mongo_db.find_one('userEvent', {'_id': mongo_db.to_object_id(ret['userEvent']['_id'])})['item']

    return ret

def CheckAndTakePayment(userId: str, eventId: str, attendeeCountAsk: int, payType: str = ''):
    ret = { 'valid': 0, 'message': '', 'spotsPaidFor': 0, 'spotsToPayFor': 0, 'amountToPay': 0,
        'availableUSD': 0, 'availableCredits': 0, 'creditsRedeemed': 0, }
    event = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(eventId)})['item']
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(event['weeklyEventId'])})['item']

    # Get how many spots user has paid for already, if any (e.g. from subscription).
    spotsPaidFor = 0
    # Check individual payments
    query = { 'forType': 'event', 'forId': eventId, 'userId': userId }
    userPayments = mongo_db.find('userPayment', query)['items']
    for userPayment in userPayments:
        if userPayment['status'] == 'complete':
            spotsPaidFor += math.floor(abs(userPayment['amountUSD']) / weeklyEvent['priceUSD'])
    # Check subscription payments.
    query = {'userId': userId, 'weeklyEventId': weeklyEvent['_id'] }
    userWeeklyEvent = mongo_db.find_one('userWeeklyEvent', query)['item']
    if userWeeklyEvent is not None:
        query = { 'userId': userId, 'forType': 'weeklyEvent', 'forId': weeklyEvent['_id'] }
        userPaymentSubscription = mongo_db.find_one('userPaymentSubscription', query)['item']
        if userPaymentSubscription is not None and userPaymentSubscription['status'] == 'complete':
            spotsPaidFor += userWeeklyEvent['attendeeCountAsk']

    ret['spotsPaidFor'] = spotsPaidFor
    ret['spotsToPayFor'] = attendeeCountAsk - spotsPaidFor
    # User has paid already.
    if ret['spotsToPayFor'] <= 0:
        ret['valid'] = 1
        return ret

    ret['valid'] = 1
    amountToPay = ret['spotsToPayFor'] * weeklyEvent['priceUSD']
    ret['amountToPay'] = amountToPay
    retMoney = _user_payment.GetUserMoney(userId)
    ret['availableUSD'] = retMoney['availableUSD']
    userCredits = GetUserEventCredits(userId, eventId = eventId)
    ret['availableCredits'] = userCredits

    # If pay type is not blank, actually take payment (otherwise it is just read only).
    if payType == 'userMoney':
        if retMoney['availableUSD'] < amountToPay:
            ret['valid'] = 0
            ret['message'] = 'User has insufficient money balance.'
            return ret
        # Deduct payment from user balance.
        retPay = _user_payment.AddPayment(userId, -1 * amountToPay, 'event', eventId)
        if not retPay['valid']:
            return retPay
        ret['availableUSD'] -= amountToPay
        ret['spotsToPayFor'] = 0
        ret['amountToPay'] = 0
        ret['spotsPaidFor'] = attendeeCountAsk
    elif payType == 'credits':
        if userCredits < ret['spotsToPayFor']:
            ret['valid'] = 0
            ret['message'] = 'User has insufficient credits.'
            return ret
        # Update user credits as redeemed.
        ret['creditsRedeemed'] = ret['spotsToPayFor']
        ret['availableCredits'] -= ret['spotsToPayFor']
        ret['spotsToPayFor'] = 0
        ret['amountToPay'] = 0
        ret['spotsPaidFor'] = attendeeCountAsk
    elif payType == 'paid' or payType == 'paidSubscription':
        ret['valid'] = 0
        ret['message'] = 'User still needs to pay for ' + str(ret['spotsToPayFor']) + ' spots.'
        return ret
    
    return ret

def GetUserEventCredits(userId: str, weeklyEventId: str = '', eventId: str = ''):
    if not weeklyEventId:
        event = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(eventId)})['item']
        weeklyEventId = event['weeklyEventId']
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(weeklyEventId)})['item']
    price = weeklyEvent['priceUSD']
    query = { 'userId': userId, 'creditsPriceUSD': { '$gte': price } }
    userEvents = mongo_db.find('userEvent', query)['items']
    credits = 0
    for userEvent in userEvents:
        credits += userEvent['creditsEarned'] - userEvent['creditsRedeemed']
    return credits

def CheckAddHostsAndAttendees(eventId: str, fillAll: int = 0):
    ret = { 'valid': 1, 'message': '', 'userIdsUpdated': [] }
    # Order with first sign up first (first come first serve).
    sortObj = {
        'createdAt': 1,
    }
    # Find all hosts.
    query = {
        'eventId': eventId,
        'hostStatus': { '$ne': 'complete' },
        'hostGroupSizeMax': { '$gt': 0 },
    }
    userEventsHosts = mongo_db.find('userEvent', query, sort_obj = sortObj)['items']
    if len(userEventsHosts) == 0 and not fillAll:
        return ret

    # Find all attendees.
    query = {
        'eventId': eventId,
        'attendeeStatus': { '$ne': 'complete' },
    }
    userEventsAttendees = mongo_db.find('userEvent', query, sort_obj = sortObj)['items']
    if len(userEventsAttendees) == 0 and not fillAll:
        return ret
    
    # Get weekly event for awarding credits to host.
    event = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(eventId)})['item']
    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(event['weeklyEventId'])})['item']

    # If there is a host who is fill but still has attendee spots, add them here.
    userEventsHostAttendees = []
    haveMoreAttendees = True
    attendeesIndex = 0
    hostIndex = 0
    hostIndexAttendees = len(userEventsHosts) - 1
    newAttendeeInfos = {}
    # Store host ids to skip them as attendee (want to leave all hosts for last).
    # If have only hosts left at end and want to fill all, will add last hosts as attendees of first hosts.
    hostIds = []
    for userEventHost in userEventsHosts:
        hostIds.append(userEventHost['userId'])
    while hostIndex < len(userEventsHosts):
        # Reset for new host.
        newAttendeeInfos = {}
        userEventHost = userEventsHosts[hostIndex]
        hostId = userEventHost['userId']
        hostSpotsLeft = userEventHost['hostGroupSizeMax'] - userEventHost['hostGroupSize']
        hostSpotsAdded = 0
        # Add host as attendee, plus any guests (up to as many as this host can host).
        attendeeSpotsNew = userEventHost['attendeeCountAsk'] - userEventHost['attendeeCount']
        if attendeeSpotsNew > hostSpotsLeft:
            attendeeSpotsNew = hostSpotsLeft
            # We DO want to treat host as a pure attendee now, so add them.
            userEventHostAttendee = copy.deepcopy(userEventHost)
            userEventHostAttendee['attendeeCount'] = userEventHost['attendeeCount'] + attendeeSpotsNew
            userEventsHostAttendees.append(userEventHostAttendee)

        hostSpotsLeft -= attendeeSpotsNew
        hostSpotsAdded += attendeeSpotsNew
        newAttendeeInfos[hostId] = {
            'attendeeCount': userEventHost['attendeeCount'] + attendeeSpotsNew,
            'attendeeCountAsk': userEventHost['attendeeCountAsk'],
            'attendeeSpotsNew': attendeeSpotsNew,
        }

        # Add any hosts that are now pure attendees (had more guests than they could host themselves).
        if hostSpotsLeft > 0:
            for index, userEvent in reversed(list(enumerate(userEventsHostAttendees))):
                userId = userEvent['userId']
                attendeeSpotsNew = userEvent['attendeeCountAsk'] - userEvent['attendeeCount']
                if attendeeSpotsNew > hostSpotsLeft:
                    attendeeSpotsNew = hostSpotsLeft
                hostSpotsLeft -= attendeeSpotsNew
                hostSpotsAdded += attendeeSpotsNew
                newAttendeeInfos[userId] = {
                    'attendeeCount': userEvent['attendeeCount'] + attendeeSpotsNew,
                    'attendeeCountAsk': userEvent['attendeeCountAsk'],
                    'attendeeSpotsNew': attendeeSpotsNew,
                }
                userEventsHostAttendees[index]['attendeeCount'] = userEvent['attendeeCount'] + attendeeSpotsNew
                if userEventsHostAttendees[index]['attendeeCount'] >= userEventsHostAttendees[index]['attendeeCountAsk']:
                    userEventsHostAttendees.pop(index)
                if hostSpotsLeft <= 0:
                    break

        # Go through (remaining) attendees and add them.
        while hostSpotsLeft > 0 and attendeesIndex < len(userEventsAttendees):
            userEvent = userEventsAttendees[attendeesIndex]
            userId = userEvent['userId']
            goToNextAttendee = True
            if userId not in hostIds:
                attendeeSpotsNew = userEvent['attendeeCountAsk'] - userEvent['attendeeCount']
                if attendeeSpotsNew > hostSpotsLeft:
                    attendeeSpotsNew = hostSpotsLeft
                    goToNextAttendee = False
                hostSpotsLeft -= attendeeSpotsNew
                hostSpotsAdded += attendeeSpotsNew
                newAttendeeInfos[userId] = {
                    'attendeeCount': userEvent['attendeeCount'] + attendeeSpotsNew,
                    'attendeeCountAsk': userEvent['attendeeCountAsk'],
                    'attendeeSpotsNew': attendeeSpotsNew,
                }
                # Update in case partial update and go again with this attendee.
                userEventsAttendees[attendeesIndex]['attendeeCount'] = newAttendeeInfos[userId]['attendeeCount']
            if goToNextAttendee:
                attendeesIndex += 1
                if attendeesIndex >= len(userEventsAttendees):
                    haveMoreAttendees = False

        # Fill in hosts in reverse order as attendees.
        if hostSpotsLeft > 0 and fillAll:
            while hostSpotsLeft > 0 and hostIndexAttendees > hostIndex:
                userEvent = userEventsHosts[hostIndexAttendees]
                userId = userEvent['userId']
                goToNextAttendee = True
                attendeeSpotsNew = userEvent['attendeeCountAsk'] - userEvent['attendeeCount']
                if attendeeSpotsNew > hostSpotsLeft:
                    attendeeSpotsNew = hostSpotsLeft
                    goToNextAttendee = False
                hostSpotsLeft -= attendeeSpotsNew
                hostSpotsAdded += attendeeSpotsNew
                newAttendeeInfos[userId] = {
                    'attendeeCount': userEvent['attendeeCount'] + attendeeSpotsNew,
                    'attendeeCountAsk': userEvent['attendeeCountAsk'],
                    'attendeeSpotsNew': attendeeSpotsNew,
                }
                # Update in case partial update and go again with this attendee.
                userEventsHosts[hostIndexAttendees]['attendeeCount'] = newAttendeeInfos[userId]['attendeeCount']
                if goToNextAttendee:
                    hostIndexAttendees -= 1
                    if hostIndexAttendees <= hostIndex:
                        break

        if hostSpotsLeft == 0 or fillAll:
            hostGroupSize = hostSpotsAdded
            credits = hostGroupSize / weeklyEvent['hostGroupSizeDefault']
            mutation = {
                '$set': {
                    'hostStatus': 'complete',
                    'hostGroupSize': hostGroupSize,
                    'creditsEarned': credits,
                    'attendeeCount': newAttendeeInfos[hostId]['attendeeCount'],
                }
            }
            if newAttendeeInfos[hostId]['attendeeCount'] == userEventHost['attendeeCountAsk']:
                mutation['$set']['attendeeStatus'] = 'complete'
            mongo_db.update_one('userEvent', {'eventId': eventId, 'userId': hostId}, mutation)
            if hostId not in ret['userIdsUpdated']:
                ret['userIdsUpdated'].append(hostId)
            # Add money to host for event.
            amount = hostGroupSize * weeklyEvent['hostMoneyPerPersonUSD']
            _user_payment.AddPayment(hostId, amount, 'event', eventId)

            # Update all attendees too.
            for attendeeId in newAttendeeInfos:
                if attendeeId != hostId:
                    mutation = {
                        '$set': {
                            'attendeeCount': newAttendeeInfos[attendeeId]['attendeeCount'],
                            # In case were host too, set to done.
                            'hostStatus': 'complete',
                            # 'hostGroupSize': 0,
                        }
                    }
                    if newAttendeeInfos[attendeeId]['attendeeCount'] == newAttendeeInfos[attendeeId]['attendeeCountAsk']:
                        mutation['$set']['attendeeStatus'] = 'complete'
                    mongo_db.update_one('userEvent', {'eventId': eventId, 'userId': attendeeId}, mutation)
                    if attendeeId not in ret['userIdsUpdated']:
                        ret['userIdsUpdated'].append(attendeeId)
        
        if not haveMoreAttendees and (not fillAll or hostIndexAttendees <= hostIndex):
            break

        hostIndex += 1

    # If more attendees who could not join, give them event credits.
    if fillAll:
        GiveUnusedCredits(eventId)
    
    return ret

def GiveUnusedCredits(eventId: str):
    ret = { 'valid': 1, 'message': '', 'userIdsUpdated': [] }
    query = {
        'eventId': eventId,
        'attendeeStatus': { '$ne': 'complete' },
    }
    userEvents = mongo_db.find('userEvent', query)['items']
    for userEvent in userEvents:
        credits = userEvent['attendeeCountAsk'] - userEvent['attendeeCount']
        mutation = {
            '$set': {
                'creditsEarned': credits,
                'attendeeStatus': 'complete',
                'hostStatus': 'complete',
            }
        }
        mongo_db.update_one('userEvent', {'eventId': eventId, 'userId': userEvent['userId']}, mutation)
        ret['userIdsUpdated'].append(userEvent['userId'])
    return ret
    