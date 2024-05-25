import json
import requests
import time

import log
import ml_config
_config = ml_config.get_config()

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

    print ('response', response)
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
                    print ('retCreate', retCreate)
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
    return ret
