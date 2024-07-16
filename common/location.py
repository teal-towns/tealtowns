import requests

import log

def LngLatToAddress(lng: float, lat: float):
    ret = { 'valid': 1, 'msg': '', 'address': {} }
    headers = {
        "User-Agent": "python-location-tt",
    }
    url = 'https://nominatim.openstreetmap.org/reverse?lat='+str(lat)+'&lon='+str(lng)+'&format=json'
    response = requests.get(url, headers=headers)
    try:
        responseData = response.json()
    except ValueError:
        ret['valid'] = 0
        log.log('warn', 'location.LngLatToAddress invalid response', response.text)
    if 'address' in responseData:
        address = responseData['address']
        ret['address'] = {
            'street': address['house_number'] + ' ' + address['road'] if 'house_number' in address and 'road' in address else '',
            'city': address['city'] if 'city' in address else '',
            'state': address['state'] if 'state' in address else '',
            'zip': address['postcode'] if 'postcode' in address else '',
            'country': address['country'] if 'country' in address else '',
        }
    return ret
