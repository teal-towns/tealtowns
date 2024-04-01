import re

import lodash
import mongo_db
from notifications_all import sms_twilio as _sms_twilio
from user_auth import user_auth as _user_auth

def SaveUser(user):
    ret = { 'valid': 0, 'message': '' } 
    query = {
        '_id': mongo_db.to_object_id(user['_id'])
    }
    saveVals = lodash.pick(user, ['first_name', 'last_name', 'lngLat'])
    if len(saveVals) > 0:
        mutation = {
            '$set': saveVals
        }
        result = mongo_db.update_one('user', query, mutation)
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
    print ('user', user)
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
        user['phoneNumberVerified'] = 1
        user['phoneNumberVerificationKey'] = user['phoneNumberVerificationKey']
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
            else:
                ret['valid'] = 1
                ret['message'] = 'Your phone number has been removed.'
    return ret
