import re

import lodash
import log
import mongo_db
from notifications_all import sms_twilio as _sms_twilio
from user_auth import user_auth as _user_auth
import ml_config

_config = ml_config.get_config()

def SaveUser(user, keys: list = ['first_name', 'last_name', 'lngLat']):
    ret = { 'valid': 0, 'message': '' } 
    query = {
        '_id': mongo_db.to_object_id(user['_id'])
    }
    saveVals = lodash.pick(user, keys)
    if 'roles' in saveVals:
        if not isinstance(saveVals['roles'], list):
            saveVals['roles'] = saveVals['roles'].split(',')
            saveVals['roles'] = [x.strip() for x in saveVals['roles']]
    if len(saveVals) > 0:
        mutation = {
            '$set': saveVals
        }
        result = mongo_db.update_one('user', query, mutation)
        ret['valid'] = 1
    return ret

def GetPhone(userId: str, requireVerified: int = 0):
    ret = { 'valid': 0, 'message': '', 'phoneNumber': '' }
    user = _user_auth.getById(userId)
    if user is not None and 'phoneNumber' in user and (requireVerified == 0 or user['phoneNumberVerified'] == 1):
        ret['phoneNumber'] = user['phoneNumber']
        ret['valid'] = 1
    return ret

def VerifyPhone(userId: str, phoneNumberVerificationKey: str):
    ret = { 'valid': 0, 'message': 'Incorrect key, please try again', 'user': {}, }
    fields = _user_auth.getUserFields()
    fields['phoneNumberVerificationKey'] = True
    user = _user_auth.getById(userId, fields = fields)
    if user is None:
        ret['message'] = 'User not found'
        return ret
    if user['phoneNumberVerificationKey'] != phoneNumberVerificationKey:
        ret['message'] = 'Incorrect key, please try again'
        return ret
    mutation = {
        '$set': {
            'phoneNumberVerificationKey': '',
            'phoneNumberVerified': 1,
        }
    }
    result = mongo_db.update_one('user', { '_id': mongo_db.to_object_id(userId) }, mutation)
    if result:
        ret['valid'] = 1
        ret['message'] = ''
        user['phoneNumberVerificationKey'] = ''
        user['phoneNumberVerified'] = 1
        ret['user'] = user
    return ret

def SendPhoneVerificationCode(userId: str, phoneNumber: str):
    ret = { 'valid': 0, 'message': '', 'phoneNumber': phoneNumber, }
    regex = re.compile('[^0-9 ]')
    phoneNumber = regex.sub('', phoneNumber)
    ret['phoneNumber'] = phoneNumber

    user = mongo_db.find_one('user', { '_id': mongo_db.to_object_id(userId) })['item']
    if user is not None:
        phoneNumberVerificationKey = ''
        if len(phoneNumber) > 0:
            phoneNumberVerificationKey = lodash.random_string(6, charsType = 'numeric')
        mutation = {
            '$set': {
                'phoneNumber': phoneNumber,
                'phoneNumberVerificationKey': phoneNumberVerificationKey,
                'phoneNumberVerified': 0,
            }
        }
        result = mongo_db.update_one('user', { '_id': mongo_db.to_object_id(userId) }, mutation)
        if result:
            if len(phoneNumber) > 0:
                retSend = _sms_twilio.Send('Your verification key is ' + phoneNumberVerificationKey, phoneNumber)
                if retSend['valid'] == 1:
                    ret['valid'] = 1
                    ret['message'] = 'A message has been sent to ' + phoneNumber + '. Check your phone for your verification key.'
                else:
                    ret['message'] = retSend['message']
                    log.log('warn', 'user.SendPhoneVerificationCode error', retSend['message'])
            else:
                ret['valid'] = 1
                ret['message'] = 'Your phone number has been removed.'
    return ret

def GetUrl(user: dict):
    return _config['web_server']['urls']['base'] + '/u/' + str(user['username'])

def GetJoinCollections(userId: str, username: str = '', limit: int = 100):
    ret = { 'valid': 1, 'message': '', }

    if len(userId) < 1 and len(username) > 0:
        user = mongo_db.find_one('user', { 'username': username })['item']
        if user is not None:
            userId = user['_id']
        else:
            ret['valid'] = 0
            ret['message'] = 'User not found'
            return ret

    sortObj = { 'createdAt': -1 }

    query = { 'adminUserIds': userId }
    fields = { 'uName': 1, 'title': 1, 'createdAt': 1, }
    ret['weeklyEventsAdmin'] = mongo_db.find('weeklyEvent', query, fields = fields, sort_obj = sortObj,
        limit = limit)['items']

    query = { 'userId': userId, 'attendeeCount': { '$gt': 0 } }
    fields = { 'eventId': 1, 'createdAt': 1, 'eventEnd': 1, 'weeklyEventUName': 1, }
    sortObj = { 'eventEnd': -1 }
    ret['userEventsAttended'] = mongo_db.find('userEvent', query, fields = fields, sort_obj = sortObj,
        limit = limit)['items']
    eventIds = []
    indexMap = {}
    for index, userEvent in enumerate(ret['userEventsAttended']):
        eventIds.append(userEvent['eventId'])
        indexMap[userEvent['eventId']] = index
    query = { 'userId': userId, 'forId': { '$in': eventIds }, 'forType': 'event', }
    fields = { 'forType': 1, 'forId': 1, 'attended': 1, 'stars': 1, 'createdAt': 1, }
    # query = { 'userId': userId }
    # fields = { 'forType': 1, 'forId': 1, 'attended': 1, 'stars': 1, 'createdAt': 1, }
    userFeedbacks = mongo_db.find('userFeedback', query, fields = fields, sort_obj = sortObj,
        limit = limit)['items']
    for userFeedback in userFeedbacks:
        ret['userEventsAttended'][indexMap[userFeedback['forId']]]['userFeedback'] = userFeedback

    sortObj = { 'createdAt': -1 }
    query = { 'userId': userId }
    fields = { 'neighborhoodUName': 1, 'roles': 1, 'status': 1, 'createdAt': 1, }
    ret['userNeighborhoods'] = mongo_db.find('userNeighborhood', query, fields = fields, sort_obj = sortObj,
        limit = limit)['items']

    return ret
