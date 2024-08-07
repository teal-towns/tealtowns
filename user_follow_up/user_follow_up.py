import datetime
import random
import threading
import time

import date_time
import log
import mongo_db
from notifications_all import email_sendgrid as _email_sendgrid
from notifications_all import sms_twilio as _sms_twilio
from user_auth import user_auth as _user_auth
from neighborhood import user_neighborhood as _user_neighborhood
from insight import user_insight as _user_insight
import ml_config

_config = ml_config.get_config()

def CheckAndDoFollowUps(now = None, maxAttempts: int = 6, nextFollowUpMinDays: int = 1, nextFollowUpMaxDays: int = 3,
    nextFollowUpHourMin = 10, nextFollowUpHourMax = 19):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 1, 'message': '', 'notifyUsernamesByType': {}, 'doneCount': 0, }

    # Remove any old follow ups (more than 21 days old, which is past max attempts times max follow up days).
    oldDate = date_time.string(now - datetime.timedelta(days = (6 + 1) * 3))
    query = { 'createdAt': { '$lt': oldDate } }
    retDelete = mongo_db.delete_many('userFollowUp', query)

    nowString = date_time.string(now)
    # Will update all as done at end.
    nextFollowUpDoneObjectIds = []
    # Find users who should be followed up with.
    retInsights = _user_insight.GetAmbassadorInsights(now, withUsers = 0)
    for forType in ['ambassadorUpdate', 'ambassadorSignUp']:
        ret['notifyUsernamesByType'][forType] = { 'sms': [], 'whatsapp': [], 'email': [], }
        userFollowUpsToAdd = []
        # We want to send follow ups either to users 1. who have not been started yet OR 2. who are past the next follow up time.
        # 1. See which users have not been started yet.
        userFollowUpsToAdd = []
        if forType == 'ambassadorSignUp':
            usernamesCheck = []
            for userInsight in retInsights['userInsights']:
                usernamesCheck.append(userInsight['username'])
            query = { 'forType': forType, 'username': { '$in': usernamesCheck } }
            usernamesStarted = mongo_db.findDistinct('userFollowUp', 'username', query)['values']
            # Remove started usernames.
            usernamesToStart = list(set(usernamesCheck).difference(usernamesStarted))
            for username in usernamesToStart:
                userFollowUpsToAdd.append({ 'username': username, 'attempt': 0, 'neighborhoodUName': '' })
            # 2. See which follow ups have already been started.
            query = { 'forType': forType, 'nextFollowUpAt': { '$lte': nowString },
                'nextFollowUpDone': 0,'username': { '$in': usernamesStarted }, }
            userFollowUps = mongo_db.find('userFollowUp', query)['items']
            userFollowUpsToAdd += userFollowUps
        elif forType == 'ambassadorUpdate':
            usernamesCheck = []
            userFollowUpMap = {}
            index = 0
            # First combine all users we may want to follow up with.
            for userNeighborhood in retInsights['userNeighborhoodsNotStarted']:
                usernamesCheck.append(userNeighborhood['username'])
                userFollowUpsToAdd.append({ 'username': userNeighborhood['username'],
                    'neighborhoodUName': userNeighborhood['neighborhoodUName'], 'attempt': 0 })
                keyTemp = userNeighborhood['username'] + '_' + userNeighborhood['neighborhoodUName']
                userFollowUpMap[keyTemp] = index
                index += 1
            for username in retInsights['userNeighborhoodWeeklyUpdatesBehindByUser']:
                usernamesCheck.append(username)
                for userNeighborhood in retInsights['userNeighborhoodWeeklyUpdatesBehindByUser'][username]:
                    neighborhoodUName = retInsights['userNeighborhoodWeeklyUpdatesBehindByUser'][username][0]['neighborhoodUName']
                    userFollowUpsToAdd.append({ 'username': username,
                        'neighborhoodUName': neighborhoodUName, 'attempt': 0 })
                    keyTemp = username + '_' + neighborhoodUName
                    userFollowUpMap[keyTemp] = index
                    index += 1
            # 1. Find users who have not been started yet.
            query = { 'forType': forType, 'username': { '$in': usernamesCheck } }
            usernamesStarted = mongo_db.findDistinct('userFollowUp', 'username', query)['values']
            # Remove started usernames.
            usernamesToStart = list(set(usernamesCheck).difference(usernamesStarted))
            # Over write any that have already been started.
            query = { 'forType': forType, 'nextFollowUpAt': { '$lte': nowString },
                'nextFollowUpDone': 0, 'username': { '$in': usernamesCheck } }
            userFollowUps = mongo_db.find('userFollowUp', query)['items']
            usernamesDue = []
            for userFollowUp in userFollowUps:
                username = userFollowUp['username']
                if username not in usernamesDue:
                    usernamesDue.append(username)
                keyTemp = username + '_' + userFollowUp['neighborhoodUName']
                userFollowUpsToAdd[userFollowUpMap[keyTemp]] = userFollowUp
            # Now REMOVE any that are not either in the not started OR due lists.
            for index, item in reversed(list(enumerate(userFollowUpsToAdd))):
                if item['username'] not in usernamesDue and item['username'] not in usernamesToStart:
                    userFollowUpsToAdd.pop(index)

        for userFollowUp in userFollowUpsToAdd:
            username = userFollowUp['username']
            neighborhoodUName = userFollowUp['neighborhoodUName']
            attempt = userFollowUp['attempt'] + 1
            # Remove if over max attempts.
            if attempt > maxAttempts:
                RemoveFollowUps(username, forType, neighborhoodUName)
                if forType == 'ambassadorSignUp':
                    _user_insight.UnsetAmbassadorSignUpSteps(username)
                elif forType == 'ambassadorUpdate':
                    _user_neighborhood.RemoveRole(username, neighborhoodUName, 'ambassador')
            else:
                user = _user_auth.getByUsername(username)
                contactType = 'email'
                if forType == 'ambassadorUpdate':
                    contactOptions = []
                    if 'phoneNumber' in user and 'phoneNumberVerified' in user and user['phoneNumberVerified'] == 1:
                        contactOptions.append('sms')
                    if 'whatsappNumber' in user and 'whatsappNumberVerified' in user and user['whatsappNumberVerified'] == 1:
                        contactOptions.append('whatsapp')
                    if 'email' in user and 'emailVerified' in user and user['emailVerified'] == 1:
                        contactOptions.append('email')
                    if len(contactOptions) < 1 and 'email' in user:
                        contactOptions = ['email']
                    contactType = random.choice(contactOptions)
                messageInfo = GetMessage(forType, contactType, attempt, user, neighborhoodUName)
                if contactType == 'email':
                    retEmail = _email_sendgrid.Send(messageInfo['subject'], messageInfo['body'], user['email'])
                    ret['notifyUsernamesByType'][forType]['email'].append(username)
                else:
                    number = user['phoneNumber']
                    messageTemplateKey = ''
                    messageTemplateVariables = {}
                    if contactType == 'whatsapp':
                        number = user['whatsappNumber']
                        messageTemplateKey = messageInfo['messageTemplateKey']
                        messageTemplateVariables = messageInfo['messageTemplateVariables']
                    retSms = _sms_twilio.Send(messageInfo['body'], number, mode = contactType,
                        messageTemplateKey = messageTemplateKey, messageTemplateVariables = messageTemplateVariables)
                    if retSms['valid']:
                        ret['notifyUsernamesByType'][forType][contactType].append(username)

                # Save past follow up as done IF exists
                if '_id' in userFollowUp:
                    nextFollowUpDoneObjectIds.append(mongo_db.to_object_id(userFollowUp['_id']))
                # Save
                timezone = 'UTC'
                if forType == 'ambassadorUpdate':
                    neighborhood = mongo_db.find_one('neighborhood', { 'uName': neighborhoodUName })['item']
                    timezone = neighborhood['timezone']
                userFollowUpNew = {
                    'username': username,
                    'neighborhoodUName': neighborhoodUName,
                    'forType': forType,
                    'contactType': contactType,
                    'followUpAt': date_time.string(now),
                    'nextFollowUpAt': GetNextFollowUp(timezone, minDays = nextFollowUpMinDays,
                        maxDays = nextFollowUpMaxDays, hourMin = nextFollowUpHourMin,
                        hourMax = nextFollowUpHourMax, now = now),
                    'nextFollowUpDone': 0,
                    'attempt': attempt,
                }
                try:
                    mongo_db.insert_one('userFollowUp', userFollowUpNew)
                except Exception as e:
                    log.log('error', 'user_follow_up.CheckAndDoFollowUps Error inserting userFollowUp: ' + str(e))
                    pass
    
    if len(nextFollowUpDoneObjectIds) > 0:
        query = { '_id': { '$in': nextFollowUpDoneObjectIds } }
        mutation = { '$set': { 'nextFollowUpDone': 1 } }
        mongo_db.update_many('userFollowUp', query, mutation)
        ret['doneCount'] = len(nextFollowUpDoneObjectIds)

    return ret

def RemoveFollowUps(username: str, forType: str, neighborhoodUName: str = ''):
    query = {
        'username': username,
        'forType': forType,
    }
    if len(neighborhoodUName) > 0:
        query['neighborhoodUName'] = neighborhoodUName
    mongo_db.delete_many('userFollowUp', query)

def CheckDoUserFollowUpLoop(timeoutMinutes = 60):
    log.log('info', 'user_follow_up.CheckDoUserFollowUpLoop starting')
    thread = None
    while 1:
        if thread is None or not thread.is_alive():
            thread = threading.Thread(target=CheckAndDoFollowUps, args=())
            thread.start()
        time.sleep(timeoutMinutes * 60)
    return None

def GetNextFollowUp(timezone: str, hourMin: int = 10, hourMax: int = 19, minDays: int = 1, maxDays: int = 3,
    now = None):
    now = now if now is not None else date_time.now()
    next = date_time.ToTimezone(now, timezone)
    days = random.randint(minDays, maxDays)
    next += datetime.timedelta(days = days)
    hour = random.randint(hourMin, hourMax)
    next = date_time.create(next.year, next.month, next.day, hour, tz = timezone)
    next = date_time.toUTC(next)
    return date_time.string(next)

def GetMessage(forType: str, contactType: str, attempt: int, user: dict, neighborhoodUName: str = ''):
    messages = []
    if forType == 'ambassadorUpdate':
        url = _config['web_server']['urls']['base'] + '/au/' + neighborhoodUName
        if contactType == 'whatsapp':
            messages = [
                {
                    'body': '',
                    'messageTemplateKey': 'ambassadorUpdateFollowUp',
                    'messageTemplateVariables': { "1": url, "2": 'team@tealtowns.org' }
                }
            ]
        elif contactType == 'sms':
            messages = [
                {
                    'body': 'Hey Ambassador! Reminder to update how many neighbors you invited this week! ' + url + ' Need support? team@tealtowns.org'
                }
            ]
        else:
            messages = [
                {
                    'subject': neighborhoodUName + ' Ambassador Update Reminder',
                    'body': 'Hey Ambassador! Reminder to update how many neighbors you invited this week! ' + url + ' Need support? team@tealtowns.org'
                }
            ]
    elif forType == 'ambassadorSignUp':
        url = _config['web_server']['urls']['base'] + '/ambassador'
        # if contactType == 'whatsapp':
        #     messages = [
        #         {
        #             'messageTemplateKey': 'ambassadorSignUpFollowUp',
        #             'messageTemplateVariables': { "1": url }
        #         }
        #     ]
        # elif contactType == 'sms':
        #     messages = [
        #         {
        #             'body': 'Reminder to submit your ambassador update of how many neighbors you invited and showed up this week! ' + url
        #         }
        #     ]
        # else:
        if contactType == 'email':
            messages = [
                {
                    'subject': 'Complate Your Ambassador Signup!',
                    'body': 'Thanks for taking the first step in your neighborhood! If you got stuck, simply contact us at team@tealtowns.org - or finish here! ' + url
                }
            ]

    return random.choice(messages)
