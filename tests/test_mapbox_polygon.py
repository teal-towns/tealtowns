import cv2
import datetime
import json
import os

from common import math_polygon as _math_polygon
from common import upload_coordinates as _upload_coordinates
from common import image_subdivide as _image_subdivide
from common import mapbox_polygon as _mapbox_polygon
import mongo_mock as _mongo_mock

_mongo_mock.InitAllCollections()

# TODO - getting error on CI https://app.circleci.com/pipelines/github/Earthshot-Labs/es_simearth/135/workflows/dfdf1b3b-ee81-4821-a5b6-c2ab50d03456/jobs/298
def xtest_mapboxElevation():
    timingStart = datetime.datetime.now()
    filePath = "./test_coordinates/Sazan_Island.kmz"
    retUpload = _upload_coordinates.UploadData(filePath, 'kmz', dataFormat = 'uint8')
    polygonLngLats = retUpload['parcels'][0]['coordinates']

    boundsLngLat = _math_polygon.MinMaxBounds(polygonLngLats)['bounds']
    retTiles = _mapbox_polygon.GetElevationTiles(boundsLngLat, zoom = None,
        maxMetersPerPixel = None, maxTiles = None)

    # TESTING
    # img = retTiles['img']
    # cv2.imwrite('./uploads/elevation-raw.png', img)
    # metersPerPixel = retTiles['metersPerPixel']
    # lngLatTopLeft = retTiles['lngLatTopLeft']
    # polygonPixels = _image_subdivide.LngLatsToPixels(polygonLngLats, lngLatTopLeft, metersPerPixel)
    # img = _image_subdivide.MaskPolygon(img, polygonPixels, grayscale = 1)
    # cv2.imwrite('./uploads/elevation-polygonMask.png', img)

    timingEnd = datetime.datetime.now()
    # assert (timingEnd - timingStart).total_seconds() < 3

# Slow test, and fails on CI. Fix & speed up.
def xtest_mapboxImageTilesExtents():
    xMeters = 5000
    yMeters = 5000
    xVertices = 2017
    yVertices = 2017

    xMeters = 1250
    yMeters = 1250
    xVertices = 505
    yVertices = 505

    xMeters = 2500
    yMeters = 2500
    xVertices = 1009
    yVertices = 1009
    # xVertices = 2017
    # yVertices = 2017

    # extents = 2
    extents = 1
    # lngLatCenter = [19.27794, 40.49500]
    # lngLatCenter = [19.28643, 40.49618]
    lngLatCenter = [-8.96051, 38.98802]

    # TESTING
    # xMeters = 1000
    # yMeters = 1000
    # lngLatCenter = [86.92447, 27.98638]

    # # lngLatCenter = [-122.44, 37.752]
    # polygonLngLats = _mapbox_polygon.PointToRectangleBounds(lngLatCenter, xMeters, yMeters)
    # boundsLngLat = _math_polygon.MinMaxBounds(polygonLngLats)['bounds']
    # print ('polygonLngLats', polygonLngLats, 'boundsLngLat', boundsLngLat)

    # # retTiles = _mapbox_polygon.GetImageTiles(None, zoom = 14, lngLatCenter = lngLatCenter,
    # #     latExtents = extents, lngExtents = extents, pixelsPerTile = 512)
    # retTiles = _mapbox_polygon.GetImageTiles(boundsLngLat, zoom = 15, pixelsPerTile = 512)
    # # TESTING
    # print ('metersPerPixel', retTiles['metersPerPixel'], retTiles['zoom'])
    # img = retTiles['img']
    # cv2.imwrite('./uploads/image-raw.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, 70])
    # metersPerPixel = retTiles['metersPerPixel']
    # lngLatTopLeft = retTiles['lngLatTopLeft']
    # polygonPixels = _image_subdivide.LngLatsToPixels(polygonLngLats, lngLatTopLeft, metersPerPixel)

    # imgMasked = _image_subdivide.MaskPolygon(img, polygonPixels, grayscale = 1)
    # cv2.imwrite('./uploads/image-polygonMask.jpg', imgMasked, [cv2.IMWRITE_JPEG_QUALITY, 70])

    # # Crop
    # boundsPixels = _math_polygon.MinMaxBounds(polygonPixels)['bounds']
    # print ('polygonPixels', polygonPixels, 'boundsPixels', boundsPixels)
    # img = img[boundsPixels['min'][1]:boundsPixels['max'][1], boundsPixels['min'][0]:boundsPixels['max'][0]]
    # cv2.imwrite('./uploads/image-cropped.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, 70])

    # # Resize to be 1 meter per pixel (input size)
    # img = cv2.resize(img, (xMeters, yMeters))
    # # cv2.imwrite('./uploads/image-resized.jpg', img, [cv2.IMWRITE_JPEG_QUALITY, 70])
    # cv2.imwrite('./uploads/image-resized.png', img)

    
    # # retTiles = _mapbox_polygon.GetElevationTiles(None, zoom = 15, lngLatCenter = lngLatCenter,
    # #     latExtents = extents, lngExtents = extents, pixelsPerTile = 512)
    # retTiles = _mapbox_polygon.GetElevationTiles(boundsLngLat, zoom = 15, pixelsPerTile = 512)
    # # TESTING
    # print ('metersPerPixel', retTiles['metersPerPixel'], retTiles['zoom'])
    # img = retTiles['img']
    # # Convert to 16 bit
    # # img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # # img = cv2.cvtColor(img, cv2.CV_16U)
    # cv2.imwrite('./uploads/image-elevation.png', img)

    # retHeightMap = _mapbox_polygon.ElevationToHeightmap(img)
    # cv2.imwrite('./uploads/image-heightmap.png', retHeightMap['img'])

    # ret = _mapbox_polygon.GetTerrainWithHeightMap(lngLatCenter, xMeters, yMeters,
    #     xVertices = xVertices, yVertices = yVertices, zoom = 15, doHeightmap = 0)
    # cv2.imwrite('./uploads/image-terrain.jpg', ret['imgTerrain'])
    # cv2.imwrite('./uploads/image-terrain-original.jpg', ret['imgTerrainOriginal'])


    ret = _mapbox_polygon.GetTerrainWithHeightMap(lngLatCenter, xMeters, yMeters,
        xVertices = xVertices, yVertices = yVertices)
    cv2.imwrite('./uploads/image-terrain.jpg', ret['imgTerrain'])
    cv2.imwrite('./uploads/image-heightmap.png', ret['imgHeightMap'])
    print ('ret elevation meters', ret['minElevationMeters'], ret['maxElevationMeters'],
        'metersPerPixel', ret['metersPerPixel'], ret['metersPerPixelOriginal'],
        'elevationMetersPixelMin', ret['elevationMetersPixelMin'], ret['elevationMetersPixelMax'])
    print ('values len', len(ret['valuesListHeightMap']), len(ret['valuesListHeightMap'][0]))
    with open('./uploads/valuesListHeightMap.json', 'w') as outfile:
        outfile.write(json.dumps(ret['valuesListHeightMap']))

    # To allow editing in both directions a landscape’s origin is in the middle of the height range.
    # So if your imported heightmap’s black point is -300 and the white point is 3580,
    # you should place your landscapes at a height of (3580 + 300) / 2 + -300 = 1600.
    # https://docs.unrealengine.com/5.2/en-US/landscape-technical-guide-in-unreal-engine/
    zPixelRange = (ret['elevationMetersPixelMax'] - ret['elevationMetersPixelMin'])
    zScale = zPixelRange * 1/512 * 100
    zOffset = (zPixelRange / 2 + ret['elevationMetersPixelMin']) * 100
    print ('zScale', zScale, 'zOffset', zOffset)
