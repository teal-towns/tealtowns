import datetime
import email_sendgrid
from notifications_all import email_mailchimp as _email_mailchimp

import date_time
import log

_config_notifications = {}
# E.g.
# _throttleLog = {
#     'key1': '2019-06-13 15:30:00',
#     'key2': '2019-06-14 10:30:00'
# }
_throttleLog = {}

def set_config(config_notifications1 = {}):
    global _config_notifications
    _config_notifications = config_notifications1
    if 'email' in _config_notifications and 'sendgrid' in _config_notifications['email'] \
         and 'api_key' in _config_notifications['email']['sendgrid']:
        email_sendgrid.Setup(_config_notifications['email']['sendgrid']['api_key'],
            _config_notifications['email'])
    if 'email' in _config_notifications and 'mailchimp' in _config_notifications['email'] \
         and 'api_key' in _config_notifications['email']['mailchimp']:
        _email_mailchimp.Setup(_config_notifications['email']['mailchimp']['api_key'],
            _config_notifications['email']['mailchimp']['server_prefix'],
            _config_notifications['email'])

def send_all(subject, body, to=None, throttleKey=None, throttleMinutes=0, skipLog=0):
    global _config_notifications
    to = to if to is not None else _config_notifications['email']['to_admin']

    block = 0
    if throttleKey is not None and throttleMinutes > 0:
        block = throttleCheck(throttleKey, throttleMinutes)['block']

    if block and not skipLog:
        log.log('info', 'notifications.send_all block', throttleKey, throttleMinutes)
    if not block:
        try:
            if 'email' in _config_notifications and to is not None:
                email_sendgrid.Send(subject, body, to)
        except Exception as e:
            if not skipLog:
                log.log('exception', 'notifications.send_all', 'email send error')
            print ('notifications.send_all error:', e)

def throttleCheck(key, throttleMinutes, now=None):
    global _throttleLog
    now = now if now is not None else date_time.now()

    block = 1
    if key not in _throttleLog:
        block = 0
    elif now > _throttleLog[key] + datetime.timedelta(minutes=throttleMinutes):
        block = 0
    if not block:
        _throttleLog[key] = now

    return {
        'block': block
    }
