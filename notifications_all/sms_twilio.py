import json
from twilio.rest import Client

import log
import ml_config
import mongo_db
_config = ml_config.get_config()

_testMode = 0

def SetTestMode(testMode: int):
    global _testMode
    _testMode = testMode

def Send(body: str, toNumber: str, fromNumber: str = '', mode: str = 'sms',
    messageTemplateKey: str = '', messageTemplateVariables: dict = {}):
    ret = { 'valid': 1, 'message': '', 'sid': '', }
    if 'twilio' not in _config or 'account_sid' not in _config['twilio'] or 'auth_token' not in _config['twilio']:
        log.log('info', 'sms_twilio.Send', 'no twilio config, skipping')
        ret['valid'] = 0
        ret['message'] = 'no twilio config'
        return ret
    accountSid = _config['twilio']['account_sid']
    authToken = _config['twilio']['auth_token']
    fromNumber = fromNumber if len(fromNumber) > 0 else _config['twilio']['from']
    prefix = '' if mode == 'sms' else mode
    fromNumber = AddPrefix(fromNumber, prefix)
    toNumber = AddPrefix(toNumber, prefix)
    if _testMode or ('test_mode' in _config['twilio'] and _config['twilio']['test_mode']):
        return ret

    log.log('info', 'sms_twilio.Send debug', 'toNumber', toNumber, 'body', body, 'fromNumber', fromNumber, 'mode', mode)

    # WhatsApp requires using message templates that are submitted on Twilio, so need to reference them.
    messageTemplateId = None
    if mode == 'whatsapp':
        messageTemplateId = _config['twilio']['message_template_ids'][messageTemplateKey] if \
            'message_template_ids' in _config['twilio'] and \
            messageTemplateKey in _config['twilio']['message_template_ids'] else None
        if messageTemplateId is None:
            ret['valid'] = 0
            ret['message'] = 'No whatsapp message template id for ' + messageTemplateKey
            log.log('info', 'sms_twilio.Send', ret['message'])
            return ret
        if 'message_service_id' not in _config['twilio']:
            ret['valid'] = 0
            ret['message'] = 'No whatsapp message service id'
            log.log('info', 'sms_twilio.Send', ret['message'])
            return ret
        try:
            client = Client(accountSid, authToken)
            message = client.messages.create(content_sid = messageTemplateId, to = toNumber, from_ = fromNumber,
                content_variables = json.dumps(messageTemplateVariables),
                messaging_service_sid = _config['twilio']['message_service_id'])
            ret['sid'] = str(message.sid)
            log.log('info', 'sms_twilio.Send', 'sent', str(message.sid), toNumber, body, fromNumber)
        except Exception as e:
            print ('sms_twilio.Send error:', e)
            ret['valid'] = 0
            ret['message'] = 'Twilio send error'
            log.log('error', 'sms_twilio.Send error', str(e), 'toNumber', toNumber, 'body', body, 'fromNumber', fromNumber)
    else:
        try:
            client = Client(accountSid, authToken)
            message = client.messages.create(body = body, to = toNumber, from_ = fromNumber)
            ret['sid'] = str(message.sid)
            log.log('info', 'sms_twilio.Send', 'sent', str(message.sid), toNumber, body, fromNumber)
        except Exception as e:
            print ('sms_twilio.Send error:', e)
            ret['valid'] = 0
            ret['message'] = 'Twilio send error'
            log.log('error', 'sms_twilio.Send error', str(e), 'toNumber', toNumber, 'body', body, 'fromNumber', fromNumber)
    return ret

def SendToUsers(body: str, userIds: list, fromNumber: str = ''):
    ret = { 'valid': 1, 'message': '', 'countSent': 0, }
    objectIds = []
    for userId in userIds:
        objectIds.append(mongo_db.to_object_id(userId))
    query = {'_id': {'$in': objectIds}, 'phoneNumberVerified': 1, }
    fields = { 'phoneNumber': 1, }
    users = mongo_db.find('user', query, fields = fields)['items']
    for user in users:
        retOne = Send(body, user['phoneNumber'], fromNumber)
        if retOne['valid']:
            ret['countSent'] += 1
    return ret

def AddPrefix(phoneNumber: str, prefix: str):
    if prefix not in phoneNumber:
        if ':' not in prefix:
            phoneNumber = prefix + ':' + phoneNumber
        else:
            phoneNumber = prefix + phoneNumber
    # Add plus.
    if '+' not in phoneNumber:
        if ':' in phoneNumber:
            phoneNumber = phoneNumber.split(':')[0] + ':+' + phoneNumber.split(':')[1]
        else:
            phoneNumber = '+' + phoneNumber
    return phoneNumber
