import json
import requests
import time
import urllib

import lodash
import ml_config
_config = ml_config.get_config()

def Search(search: str):
    ret = { 'valid': 1, 'message': '', 'products': [] }
    if 'ecommerceapi' not in _config or 'api_key' not in _config['ecommerceapi']:
        ret['valid'] = 0
        ret['message'] = 'no ecommerceapi config'
        return ret
    payload = {'api_key': _config['ecommerceapi']['api_key'], 'url':'https://www.amazon.com/s?k=' + urllib.parse.quote_plus(search)}
    # print ('payload', payload)
    start = time.time()
    resp = requests.get('https://api.ecommerceapi.io/amazon_search', params=payload)
    # print ('time', time.time() - start)
    # print (resp.text)
    res = json.loads(resp.text)
    # fields = ['title', 'image' 'stars', 'total_reviews', 'optimized_url', 'asin', 'price', 'price_symbol']
    fields = ['title', 'image', 'price', 'price_symbol']
    for result in res['results']:
        if 'price' in result and 'price_symbol' in result and 'title' in result and 'image' in result:
            ret['products'].append(lodash.pick(result, fields))
    return ret
