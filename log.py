import datetime
import logging
import logging.config
import loggly.handlers
import os
import simplejson as json

import date_time
import ml_config
import notifications

_logger = None
_error_logger = None
_logDatetimes = []
_logLevel = None

def init_logger(config):
    global _logger
    global _error_logger
    global _logLevel

    # Only initialize once.
    if _logger is not None and _error_logger is not None:
        return {
            'logger': _logger,
            'error_logger': _error_logger
        }

    if _logger is None:
        if 'logging_config_file' in config:
            logging.config.fileConfig(config['logging_config_file'])
        _logger = logging.getLogger('trader-logger')
        _logger.setLevel(config['log_level'] or logging.DEBUG)
        _logLevel = config['log_level']
        if config['logging']:
            _logger.addHandler(logging.FileHandler("debug.log"))
        if config['debug']:
            _logger.addHandler(logging.StreamHandler())
        _error_logger = logging.getLogger('error-logger')
        _error_logger.addHandler(logging.FileHandler("error.log"))
    return {
        'logger': _logger,
        'error_logger': _error_logger
    }

def get_logger():
    global _logger
    return _logger

def getLogsSize():
    global _logDatetimes
    return {
        'totalLogDatetimes': len(_logDatetimes)
    }

def removeOldLogs(logDatetimes, minDatetime=None, now=None):
    now = now if now is not None else date_time.now()
    minDatetime = minDatetime if minDatetime is not None else now - datetime.timedelta(hours=1)

    for index, logDatetime in reversed(list(enumerate(logDatetimes))):
        if logDatetime < minDatetime:
            del logDatetimes[index]
    return logDatetimes

def getSystemName():
    return os.uname().nodename.replace('.local', '').lower()

def updateTracker(now=None):
    global _logDatetimes

    now = now if now is not None else date_time.now()

    logTracker = ml_config.getValue('log_tracker')
    if logTracker is not None:
        _logDatetimes = removeOldLogs(_logDatetimes, now=now)
        _logDatetimes.append(now)

        count = len(_logDatetimes)
        if count < logTracker['min_per_hour']:
            subject = 'Log tracker below minimum ' + str(count) + ' ' + \
                str(logTracker['min_per_hour']) + ' ' + str(getSystemName())
            notifications.send_all(subject, 'Check server for details', None, 'logTrackerMinPerHour', 240, skipLog=1)
        if count > logTracker['max_per_hour']:
            subject = 'Log tracker above maximum ' + str(count) + ' ' + \
                str(logTracker['max_per_hour']) + ' ' + str(getSystemName())
            notifications.send_all(subject, 'Check server for details', None, 'logTrackerMaxPerHour', 240, skipLog=1)

def log(level_key='debug', *messages):
    global _logger
    global _logLevel

    # Depending on config log level, log may not be shown; only want to tracker
    # visible logs.
    logDisplayed = 0

    if level_key == 'print':
        print (messages)
        logDisplayed = 1
    else:
        message = combine_message_parts(messages)
        if level_key == 'debug':
            _logger.debug(message)
            if _logLevel <= 10:
                logDisplayed = 1
        elif level_key == 'info':
            _logger.info(message)
            if _logLevel <= 20:
                logDisplayed = 1
        elif level_key == 'warn':
            _logger.warn(message)
            if _logLevel <= 30:
                logDisplayed = 1
        elif level_key == 'exception':
            _logger.exception(message)
            if _logLevel <= 40:
                logDisplayed = 1

    if logDisplayed:
        updateTracker()

def join(*messages):
    return combine_message_parts(messages)

def combine_message_parts(messages):
    messageItems = []
    for message_part in messages:
        if isinstance(message_part, str):
            messageItems.append(message_part)
        elif isinstance(message_part, int) or isinstance(message_part, float):
            messageItems.append(str(message_part))
        elif isinstance(message_part, datetime.datetime):
            messageItems.append(date_time.string(message_part))
        else:
            messageItems.append(json.dumps(message_part))
    # return ",".join(messageItems)
    return messageItems
