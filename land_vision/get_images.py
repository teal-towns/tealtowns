import cv2
import json
import requests
import numpy as np
import matplotlib.pyplot as plt

from mapbox import mapbox_polygon as _mapbox_polygon
  


def get_mapbox_static_image(latitude, longitude, zoom=15, width=400, height=300, style='streets-v11'):

    base_url = f'https://api.mapbox.com/styles/v4/mapbox.{style}/static/{longitude},{latitude},{zoom}/{width}x{height}'
    access_token = 'pk.eyJ1IjoibHVrZW0xMjMiLCJhIjoiY2ttc2U4NHkzMGd5bzJ2bG1neTBvdnRqOCJ9.o4fk2TYxHvDtEBu4ddgrmA'
    
    params = {
        'access_token': access_token,
    }
    response = requests.get(base_url, params=params)

    if response.status_code == 200:
        return response.content
    else:
        print(f"Error {response.status_code}: {response.text}")
        return None

def get_mapbox_naip_image(lngLat, zoom, tileType = 'satellite', pixelsPerTile = 512):
    ret = { 'valid': 1, 'img': None }
    row = _mapbox_polygon.LatitudeToTile(lngLat[1], zoom)
    column = _mapbox_polygon.LongitudeToTile(lngLat[0], zoom)
    suffix = '@2x' if pixelsPerTile == 512 else ''
    url = f'/v4/mapbox.{tileType}/' + str(zoom) + '/' + str(column) + '/' + str(row) + suffix + '.jpg'
    if tileType == 'elevation':
        url = '/v4/mapbox.terrain-rgb/' + str(zoom) + '/' + str(column) + '/' + str(row) + suffix + '.pngraw'
    retTile = _mapbox_polygon.Request('get', url, {}, responseType = '')
    bytesArray = np.frombuffer(retTile['data'].content, dtype = np.uint8)
    ret['img'] = cv2.imdecode(bytesArray, 1)
    return ret



if __name__ == "__main__":
    latitude = 37.7749  # Replace with the desired latitude
    longitude = -122.4194  # Replace with the desired longitude
    lngLat = [-122.033802, 37.977362]
    zoom = 15
    image_data = get_mapbox_naip_image(lngLat, zoom, tileType = 'naip', pixelsPerTile = 1024)
    if image_data:
        np.save('./uploads/images/naip_image_z17',image_data['img'])
        #with open('./uploads/images/naip_image.jpg', 'wb') as f:
            #f.write(image_data['img'])
        print('Image saved successfully!', image_data['img'].shape)
        #print(image_data)