# import cv2
# import json

# from mapbox import mapbox_polygon as _mapbox_polygon
# from land_vision import land_vision as _land_vision

# def test_seeLand():
#     imageUrl = 'https://ultralytics.com/images/bus.jpg'
#     imageUrl = './uploads/bus.jpg'

#     lngLat = [-122.033802, 37.977362]
#     zoom = 16
#     # zoom = 17
#     # ret = _mapbox_polygon.GetImageTileByLngLat(lngLat, zoom = zoom, pixelsPerTile = 512)
#     # imageUrl = './uploads/land-vision-orig.jpg'
#     # cv2.imwrite(imageUrl, ret['img'])

#     ret = _mapbox_polygon.GetVectorTileByLngLat(lngLat, zoom = zoom, tileType = 'street')
#     print ('ret', json.dumps(ret['tile'], indent = 2))

#     # _land_vision.seeLand(imageUrl)
