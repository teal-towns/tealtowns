from twilio.rest import Client

import log
import ml_config
_config = ml_config.get_config()

_testMode = 0

def SetTestMode(testMode: int):
    global _testMode
    _testMode = testMode

def Send(body: str, toNumber: str, fromNumber: str = ''):
    ret = { 'valid': 1, 'message': '', 'sid': '', }
    if 'twilio' not in _config or 'account_sid' not in _config['twilio'] or 'auth_token' not in _config['twilio']:
        log.log('info', 'sms_twilio.Send', 'no twilio config')
        ret['valid'] = 0
        ret['message'] = 'no twilio config'
        return ret
    accountSid = _config['twilio']['account_sid']
    authToken = _config['twilio']['auth_token']
    fromNumber = fromNumber if len(fromNumber) > 0 else _config['twilio']['from']
    if toNumber[0] != '+':
        toNumber = '+' + toNumber
    if _testMode or ('test_mode' in _config['twilio'] and _config['twilio']['test_mode']):
        return ret
    try:
        client = Client(accountSid, authToken)
        message = client.messages.create(body = body, to = toNumber, from_ = fromNumber)
        ret['sid'] = str(message.sid)
        # log.log('info', 'sms_twilio.Send', 'sent', str(message.sid), toNumber, body, fromNumber)
    except Exception as e:
        print ('sms_twilio.Send error:', e)
        ret['valid'] = 0
        ret['message'] = 'Twilio send error'
        log.log('warn', 'sms_twilio.Send error', str(e))
    return ret
