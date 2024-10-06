import threading

from common import mongo_db_crud as _mongo_db_crud
import lodash
import mongo_db
from event import weekly_event as _weekly_event
from notifications_all import email_sendgrid as _email_sendgrid
from notifications_all import sms_twilio as _sms_twilio
from user_auth import user as _user
from user import user_interest as _user_interest

_testMode = 0
def SetTestMode(testMode: int):
    global _testMode
    _testMode = testMode

def Save(userAvailability: dict, useThread: int = 1):
    userAvailability['availableTimesByDay'] = SortAndMergeTimes(userAvailability['availableTimesByDay'])
    ret = _mongo_db_crud.Save('userAvailability', userAvailability, checkGetKey = 'username')
    if useThread and not _testMode:
        thread = threading.Thread(target=CheckCommonInterestsAndTimesByUser, args=(userAvailability['username'],))
        thread.start()
        return ret
    retCheck = CheckCommonInterestsAndTimesByUser(userAvailability['username'])
    ret['weeklyEventsCreated'] = retCheck['weeklyEventsCreated']
    ret['weeklyEventsInvited'] = retCheck['weeklyEventsInvited']
    ret['notifyUserIds'] = retCheck['notifyUserIds']
    return ret

def SortAndMergeTimes(availableTimesByDay: list):
    for index, day in enumerate(availableTimesByDay):
        availableTimesByDay[index]['times'] = lodash.sort2D(availableTimesByDay[index]['times'], 'start')
        # Merge any overlapping times.
        for indexTime, time in reversed(list(enumerate(availableTimesByDay[index]['times']))):
            if indexTime > 0:
                past = availableTimesByDay[index]['times'][indexTime - 1]
                current = availableTimesByDay[index]['times'][indexTime]
                if current['start'] != '' and current['end'] != '' and past['start'] != '' and past['end'] != '':
                    if past['end'] >= current['start']:
                        newEnd = max(past['end'], current['end'])
                        availableTimesByDay[index]['times'][indexTime - 1]['end'] = newEnd
                        availableTimesByDay[index]['times'].pop(indexTime)
                else:
                    availableTimesByDay[index]['times'].pop(indexTime)
    # Sort days of week too.
    availableTimesByDay = lodash.sort2D(availableTimesByDay, 'dayOfWeek')
    return availableTimesByDay

def CheckCommonInterestsAndTimesByUser(username: str, minMatchedUsers: int = 3, maxCreatedEvents: int = 1):
    ret = { 'valid': 1, 'message': '', 'matches': [], 'weeklyEventsCreated': [], 'weeklyEventsInvited': [],
        'notifyUserIds': { 'sms': [], 'email': [] }, }
    eventInterests = _user_interest.GetEventInterests()['eventInterests']
    # Check all neighborhoods this user is in. Update: only check default neighborhood.
    query = { 'username': username, 'status': 'default' }
    fields = { 'username': 1, 'neighborhoodUName': 1 }
    userNeighborhoods = mongo_db.find('userNeighborhood', query, fields = fields)['items']
    if len(userNeighborhoods) <= 0:
        return ret
    userAvailability = mongo_db.find_one('userAvailability', {'username': username})['item']
    if userAvailability is None:
        return ret
    userInterest = mongo_db.find_one('userInterest', {'username': username})['item']
    if userInterest is None or len(userInterest['interests']) <= 0:
        return ret
    interests = userInterest['interests']
    hostInterests = userInterest['hostInterests']
    neighborhoodUNames = []
    for userNeighborhood in userNeighborhoods:
        neighborhoodUNames.append(userNeighborhood['neighborhoodUName'])
    # For performance, make one database call here and group to filter
    # (otherwise can easily make tens or hundreds of database calls and take tens of seconds total).
    query = { 'neighborhoodUName': { '$in': neighborhoodUNames }, 'username': { '$ne': username } }
    fields = { 'username': 1, 'neighborhoodUName': 1 }
    userNeighborhoodsCheck = mongo_db.find('userNeighborhood', query, fields = fields)['items']
    usernamesByNeighborhood = {}
    usernamesAll = []
    for userNeighborhood in userNeighborhoodsCheck:
        if userNeighborhood['neighborhoodUName'] not in usernamesByNeighborhood:
            usernamesByNeighborhood[userNeighborhood['neighborhoodUName']] = []
        if userNeighborhood['username'] not in usernamesByNeighborhood[userNeighborhood['neighborhoodUName']]:
            usernamesByNeighborhood[userNeighborhood['neighborhoodUName']].append(userNeighborhood['username'])
        if userNeighborhood['username'] not in usernamesAll:
            usernamesAll.append(userNeighborhood['username'])

    query = { 'username': { '$in': usernamesAll }, 'interests': { '$in': interests } }
    fields = { 'username': 1, 'interests': 1, 'hostInterests': 1, }
    userInterestsCheck = mongo_db.find('userInterest', query)['items']
    usernamesByInterest = {}
    usernamesByHostInterest = {}
    for userInterest in userInterestsCheck:
        for interest1 in userInterest['interests']:
            if interest1 not in usernamesByInterest:
                usernamesByInterest[interest1] = []
            if userInterest['username'] not in usernamesByInterest[interest1]:
                usernamesByInterest[interest1].append(userInterest['username'])
        for interest2 in userInterest['hostInterests']:
            if interest2 not in usernamesByHostInterest:
                usernamesByHostInterest[interest2] = []
            if userInterest['username'] not in usernamesByHostInterest[interest2]:
                usernamesByHostInterest[interest2].append(userInterest['username'])

    for interest in interests:
        interestMatch = False
        # First check existing events (and just invite to those, if exist with interest and availability match).
        query = { 'tags': { '$in': [ interest ] }, 'neighborhoodUName': { '$in': neighborhoodUNames } }
        weeklyEvents = mongo_db.find('weeklyEvent', query)['items']
        retEvents = GetWeeklyEventInUserAvabilability(weeklyEvents, userAvailability)
        if len(retEvents['weeklyEvents']) > 0:
            retNotify = NotifyUserOfEvent(username, interest, retEvents['weeklyEvents'][0])
            ret['notifyUserIds']['sms'] += retNotify['notifyUserIds']['sms']
            ret['notifyUserIds']['email'] += retNotify['notifyUserIds']['email']
            ret['weeklyEventsInvited'].append(retEvents['weeklyEvents'][0])
            interestMatch = True

        # If have an event, done with this interest.
        if interestMatch:
            break

        minPeople = minMatchedUsers
        minHosts = 0
        eventInterest = None
        if 'event_' in interest and interest in eventInterests:
            eventInterest = eventInterests[interest]
            if 'minPeople' in eventInterest:
                minPeople = eventInterest['minPeople']
            elif eventInterest['hostGroupSizeDefault'] > minPeople:
                minPeople = eventInterest['hostGroupSizeDefault']
            if eventInterest['hostGroupSizeDefault'] > 0:
                minHosts = 1

        for userNeighborhood in userNeighborhoods:
            # Check all users per each neighborhood
            neighborhoodUName = userNeighborhood['neighborhoodUName']
            # Further filter by overlapping interest.
            usernamesFinal = []
            usernamesHostsFinal = []
            if neighborhoodUName in usernamesByNeighborhood:
                for username1 in usernamesByNeighborhood[neighborhoodUName]:
                    if interest in usernamesByInterest and username1 in usernamesByInterest[interest]:
                        usernamesFinal.append(username1)
                    if interest in usernamesByHostInterest and username1 in usernamesByHostInterest[interest]:
                        usernamesHostsFinal.append(username1)

            userIsHostInterest = True if interest in hostInterests else False

            # +1 for self user
            if len(usernamesFinal) + 1 < minPeople:
                continue
            # Check if hosts are required too.
            if len(usernamesHostsFinal) < minHosts and not userIsHostInterest:
                continue
            # If hosts are required, make sure at least one is available, otherwise skip.
            requiredUsernames = usernamesHostsFinal if minHosts > 0 else []
            if userIsHostInterest:
                requiredUsernames = []

            # See if any overlapping availability.
            query = { 'username': { '$in': usernamesFinal } }
            userAvailabilitys = mongo_db.find('userAvailability', query)['items']
            if len(userAvailabilitys) <= 0:
                continue
            retTimes = FindTimeOverlaps(userAvailability, userAvailabilitys, minMatchedUsers = minPeople,
                requiredUsernames = requiredUsernames)
            if retTimes['maxMatches'] >= minPeople:
                ret['matches'].append({ 'neighborhoodUName': neighborhoodUName, 'interest': interest,
                    'matchTime': retTimes['bestMatchTime'] })
                # Create event and make admin and invite all matching usernames.
                neighborhood = mongo_db.find_one('neighborhood', {'uName': neighborhoodUName})['item']
                users = mongo_db.find('user', {'username': { '$in': retTimes['bestMatchTime']['usernames'] }})['items']
                userIds = [ user['_id'] for user in users ]
                weeklyEvent = {
                    'neighborhoodUName': neighborhoodUName,
                    'tags': [ interest ],
                    'title': interest + ' Event',
                    'description': 'You and several locals matched on this interest at this time! Update this event with more details.',
                    'dayOfWeek': retTimes['bestMatchTime']['dayOfWeek'],
                    'startTime': retTimes['bestMatchTime']['startTime'],
                    'endTime': retTimes['bestMatchTime']['endTime'],
                    'location': neighborhood['location'],
                    'adminUserIds': userIds,
                    'hostGroupSizeDefault': 0,
                    'priceUSD': 0,
                    'rsvpDeadlineHours': 0,
                    'imageUrls': [],
                }

                if 'event_' in interest and interest in eventInterests:
                    eventInterestsToCopy = lodash.omit(eventInterests[interest],
                        ['minPeople', 'hostRequirements', 'hostDetails'])
                    weeklyEvent = lodash.extend_object(weeklyEvent, eventInterestsToCopy)

                retSave = _weekly_event.Save(weeklyEvent)
                weeklyEvent = retSave['weeklyEvent']
                for username1 in retTimes['bestMatchTime']['usernames']:
                    retNotify = NotifyUserOfEvent(username1, interest, weeklyEvent['uName'])
                    ret['notifyUserIds']['sms'] += retNotify['notifyUserIds']['sms']
                    ret['notifyUserIds']['email'] += retNotify['notifyUserIds']['email']
                ret['weeklyEventsCreated'].append(weeklyEvent)
                ret['weeklyEventsInvited'].append(weeklyEvent)
                interestMatch = True
                break
        # Only do 1 event per interest.
        if interestMatch or len(ret['weeklyEventsCreated']) >= maxCreatedEvents:
            break
    return ret

def NotifyUserOfEvent(username: str, interest: str, weeklyEventUName: str):
    ret = { 'valid': 1, 'message': '', 'notifyUserIds': { 'sms': [], 'email': [] }, }
    retPhone = _user.GetPhone('', username = username)
    body = 'There is a local ' + interest + ' event that fits your schedule! ' + _weekly_event.GetUrlUName(weeklyEventUName)
    if retPhone['valid']:
        messageTemplateVariables = { "1": interest, "2": _weekly_event.GetUrlUName(weeklyEventUName) }
        retSms = _sms_twilio.Send(body, retPhone['phoneNumber'], mode = retPhone['mode'],
            messageTemplateKey = 'eventInterestMatch', messageTemplateVariables = messageTemplateVariables)
        ret['notifyUserIds']['sms'].append(retPhone['userId'])
    elif len(retPhone['email']) > 0:
        body = ''
        retEmail = _email_sendgrid.Send('Event Availability Match for ' + interest + '!', body, retPhone['email'])
        ret['notifyUserIds']['email'].append(retPhone['userId'])
    return ret

def GetWeeklyEventInUserAvabilability(weeklyEvents: list, userAvailability: dict):
    ret = { 'valid': 1, 'message': '', 'weeklyEvents': [], }
    for weeklyEvent in weeklyEvents:
        matchFound = False
        for day in userAvailability['availableTimesByDay']:
            dayOfWeek = day['dayOfWeek']
            if weeklyEvent['dayOfWeek'] == dayOfWeek:
                for time in day['times']:
                    # Handle end in next day.
                    eventEnd = weeklyEvent['endTime']
                    startHour = int(weeklyEvent['startTime'][0:2].replace(':', ''))
                    endHour = int(weeklyEvent['endTime'][0:2].replace(':', ''))
                    if endHour < startHour:
                        endHour += 24
                        eventEnd = '24:00'
                    if time['start'] >= weeklyEvent['startTime'] and time['start'] <= eventEnd:
                        ret['weeklyEvents'].append(weeklyEvent)
                        matchFound = True
                        break
            if matchFound:
                break
    return ret

def FindTimeOverlaps(userAvailability: dict, userAvailabilitys: list, minMatchedUsers: int = 3,
    minDurationMinutes: int = 60, stepMinutes: int = 30, requiredUsernames: list = []):
    ret = { 'valid': 1, 'message': '', 'matchTimes': [], 'maxMatches': 0, 'maxMatchIndex': -1, 'bestMatchTime': {}, }
    if len(userAvailabilitys) <= 0:
        return ret
    for day in userAvailability['availableTimesByDay']:
        dayOfWeek = day['dayOfWeek']
        # Go through all users in minDurationMinutes chunks and count total per each time window.
        matchesByTime = {}
        startHour = 0
        startMinute = 0
        while startHour <= 23:
            endHour = startHour
            endMinute = startMinute + minDurationMinutes
            if endMinute >= 60:
                endHour += 1
                endMinute -= 60
            if endHour >= 24:
                endHour -= 24
            startTime = str(startHour).zfill(2) + ':' + str(startMinute).zfill(2)
            endTime = str(endHour).zfill(2) + ':' + str(endMinute).zfill(2)
            mainUserMatch = False
            for time in day['times']:
                if time['start'] <= startTime and time['end'] >= endTime:
                    mainUserMatch = True
                    break
                elif time['start'] >= endTime:
                    break

            if mainUserMatch:
                matchUsernames = [userAvailability['username']]
                # Check all other users now.
                for userAvailability1 in userAvailabilitys:
                    for day1 in userAvailability1['availableTimesByDay']:
                        if day1['dayOfWeek'] == dayOfWeek:
                            for time1 in day1['times']:
                                if time1['start'] <= startTime and time1['end'] >= endTime:
                                    matchUsernames.append(userAvailability1['username'])
                                    break
                                elif time1['start'] >= endTime:
                                    break
                            break

                if len(matchUsernames) >= minMatchedUsers:
                    requiredMatch = True
                    if len(requiredUsernames) > 0:
                        requiredMatch = False
                        for requiredUsername in requiredUsernames:
                            if requiredUsername in matchUsernames:
                                requiredMatch = True
                                break
                    if requiredMatch:
                        match1 = { 'dayOfWeek': dayOfWeek, 'startTime': startTime, 'endTime': endTime,
                            'usernames': matchUsernames }
                        ret['matchTimes'].append(match1)
                        if len(matchUsernames) > ret['maxMatches']:
                            ret['maxMatches'] = len(matchUsernames)
                            ret['maxMatchIndex'] = len(ret['matchTimes']) - 1
                            ret['bestMatchTime'] = match1

            startMinute += stepMinutes
            if startMinute >= 60:
                startHour += 1
                startMinute -= 60
    return ret
