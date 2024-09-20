import datetime
import json
import re
import requests
import threading
import time

import date_time
import lodash
import log
import mongo_db
import ml_config
_config = ml_config.get_config()

_testMode = 0

def SetTestMode(testMode: int):
    global _testMode
    _testMode = testMode

def MakeRequest(method: str, urlPath: str, params: dict = {}, maxRetries: int = 0, retryCount: int = 0):
    headers = {
        "Authorization": "Bearer " + _config['mercury']['api_token'],
        "accept": "application/json",
    }
    url = 'https://api.mercury.com/api/v1/' + urlPath
    auth = (_config['mercury']['api_token'], '')
    if method == 'get':
        response = requests.get(url, headers=headers, params=params, auth=auth)
    elif method == 'post':
        headers['content-type'] = 'application/json'
        response = requests.post(url, headers=headers, data=json.dumps(params), auth=auth)
    elif method == 'delete':
        response = requests.delete(url, headers=headers, data=json.dumps(params), auth=auth)

    valid = 1
    responseData = {}
    if not str(response.status_code).startswith('2'):
        log.log('warn', 'pay_mercury.MakeRequest bad status code', response.status_code,
            response.text, method, urlPath, headers, params)
        valid = 0
    try:
        responseData = response.json()
    except ValueError:
        valid = 0
        log.log('warn', 'pay_mercury.MakeRequest invalid response', response.text)

    if not valid and retryCount < maxRetries:
        log.log('warn', 'pay_mercury.MakeRequest retrying', retryCount, maxRetries, method,
            urlPath)
        time.sleep(1)
        return MakeRequest(method, urlPath = urlPath, params = params,
            maxRetries = maxRetries, retryCount = (retryCount + 1))

    return {
        'valid': valid,
        'data': responseData,
    }


def GetAndAddRecipients():
    ret = { 'valid': 1, 'message': '', 'recipientsCreated': 0, 'recipients': [], }
    if 'recipients' in _config['mercury']:
        retGet = MakeRequest('get', 'recipients')
        if 'recipients' in retGet['data'] and len(retGet['data']['recipients']) > 0:
            for configRecipient in _config['mercury']['recipients']:
                found = 0
                for recipient in retGet['data']['recipients']:
                    if recipient['nickname'] == configRecipient['key']:
                        found = 1
                        break
                if found:
                    ret['recipients'].append(recipient)
                else:
                    params = { 'name': configRecipient['key'], 'nickname': configRecipient['key'],
                        'emails': ['luke.madera@gmail.com'],
                        'paymentMethod': 'electronic',
                        'electronicRoutingInfo': {
                            'accountNumber': configRecipient['account_number'],
                            'routingNumber': configRecipient['routing_number'],
                            'electronicAccountType': 'businessChecking',
                            'address': {
                                'address1': '4501 23rd Avenue S',
                                'city': 'Fargo',
                                'region': 'ND',
                                'postalCode': '58104',
                                'country': 'US',
                            },
                        }
                    }
                    retCreate = MakeRequest('post', 'recipients', params)
                    # print ('retCreate', retCreate)
                    if retCreate['valid']:
                        ret['recipientsCreated'] += 1
                        ret['recipients'].append(retCreate['data'])
    return ret

def GetAccounts():
    ret = { 'valid': 1, 'message': '', 'accounts': [], }
    retGet = MakeRequest('get', 'accounts')
    if retGet['valid']:
        ret['accounts'] = retGet['data']['accounts']
    return ret

def GetAccountByKey(key: str):
    ret = { 'valid': 1, 'message': '', 'account': {}, }
    if 'accounts' in _config['mercury']:
        for configAccount in _config['mercury']['accounts']:
            if configAccount['key'] == key:
                retAccounts = GetAccounts()
                for account in retAccounts['accounts']:
                    if account['id'] == configAccount['account_id']:
                        ret['account'] = account
                        break
    return ret

def GetRecipientByKey(key: str):
    ret = { 'valid': 1, 'message': '', 'recipient': {}, }
    if 'recipients' in _config['mercury']:
        for configRecipient in _config['mercury']['recipients']:
            if configRecipient['key'] == key:
                retRecipients = GetAndAddRecipients()
                for recipient in retRecipients['recipients']:
                    if recipient['nickname'] == configRecipient['key']:
                        ret['recipient'] = recipient
                        break
    return ret

def MakeTransaction(accountKey: str, recipientKey: str, amountUSD: float, transactionKey: str):
    ret = { 'valid': 0, 'message': '', 'transaction': {}, }
    if _testMode or ('test_mode' in _config['mercury'] and _config['mercury']['test_mode']):
        print ('pay_mercury.MakeTransaction TEST MODE, skipping', accountKey, recipientKey, amountUSD, transactionKey)
        ret['valid'] = 1
        return ret
    retAccount = GetAccountByKey(accountKey)
    retReipient = GetRecipientByKey(recipientKey)
    if 'id' in retAccount['account'] and 'id' in retReipient['recipient']:
        params = {
            'recipientId': retReipient['recipient']['id'],
            'amount': amountUSD,
            'paymentMethod': 'ach',
            'idempotencyKey': transactionKey,
        }
        retOne = MakeRequest('post', 'account/' + retAccount['account']['id'] + '/transactions', params)
        if retOne['valid']:
            ret['valid'] = 1
            ret['transaction'] = retOne['data']
    else:
        ret['message'] = 'account or recipient not found'
        log.log('error', 'pay_mercury.MakeTransaction error', ret['message'], accountKey, recipientKey)
    return ret

def QueueTransaction(accountKey: str, recipientKey: str, amountUSD: float, forId: str, forType: str, now = None):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 1, 'message': '', 'mercuryPayOut': {}, }
    mercuryPayOut = {
        'accountKey': accountKey,
        'recipientKey': recipientKey,
        'amountUSD': amountUSD,
        'forId': forId,
        'forType': forType,
        'paidOut': 0,
    }
    retOne = mongo_db.insert_one('mercuryPayOut', mercuryPayOut, now = now)
    ret['mercuryPayOut'] = retOne['item']
    return ret

def CheckDoQueuedTransactions(daysDelay: int = 7, now = None):
    now = now if now is not None else date_time.now()
    ret = { 'valid': 1, 'message': '', 'paidOutIds': [], 'amountUSDByKey': {}, }
    maxDateString = date_time.string(now - datetime.timedelta(days = daysDelay))
    query = { 'paidOut': 0, 'createdAt': { '$lte': maxDateString } }
    # log.log('info', 'pay_mercury.CheckDoQueuedTransactions maxDate ' + maxDateString)
    items = mongo_db.find('mercuryPayOut', query)['items']
    objIdsByKeys = {}
    idsByKeys = {}
    amountUSDSumsByKeys = {}
    for item in items:
        key = item['accountKey'] + '_' + item['recipientKey']
        if key not in amountUSDSumsByKeys:
            amountUSDSumsByKeys[key] = 0
        amountUSDSumsByKeys[key] += item['amountUSD']
        if key not in objIdsByKeys:
            objIdsByKeys[key] = []
        objIdsByKeys[key].append(mongo_db.to_object_id(item['_id']))
        if key not in idsByKeys:
            idsByKeys[key] = []
        idsByKeys[key].append(item['_id'])
    for key in amountUSDSumsByKeys:
        amountUSD = amountUSDSumsByKeys[key]
        if amountUSD > 0:
            # Only should be 1 per day (per account and recipient key) so use date as key.
            nowString = date_time.string(now).split('+')[0]
            transactionKey = 'queuedPayOut_' + key + '_' + nowString
            regex = re.compile('[^a-zA-Z0-9_]')
            transactionKey = regex.sub('', transactionKey)
            retOne = MakeTransaction(key.split('_')[0], key.split('_')[1], amountUSD, transactionKey)
            if retOne['valid']:
                mutation = { '$set': { 'paidOut': 1 } }
                mongo_db.update_many('mercuryPayOut', { '_id': { '$in': objIdsByKeys[key] } }, mutation)
                ret['paidOutIds'] += idsByKeys[key]
                ret['amountUSDByKey'][key] = amountUSD
            else:
                ret['message'] = 'pay out failed'
                log.log('error', 'pay_mercury.CheckDoQueuedTransactions error. key ' + key + ' amountUSD ' + str(amountUSD))
    return ret

def CheckDoTransactionsLoop(timeoutMinutes = 60 * 24):
    log.log('info', 'pay_mercury.CheckDoTransactionsLoop starting')
    thread = None
    while 1:
        if thread is None or not thread.is_alive():
            thread = threading.Thread(target=CheckDoQueuedTransactions, args=())
            thread.start()
        time.sleep(timeoutMinutes * 60)
    return None
