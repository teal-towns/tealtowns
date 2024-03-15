import cv2
import math
import numpy
import requests
import time
import mapbox_vector_tile

import log
from common import image_subdivide as _image_subdivide
from common import math_polygon as _math_polygon
from mapbox import mapbox_vector_tile as _mapbox_vector_tile
import ml_config
import number

_inited = False
_accessToken = ''

def GetAccessToken():
    global _inited
    global _accessToken
    if not _inited:
        config = ml_config.get_config()
        if 'mapbox' in config and 'access_token' in config['mapbox']:
            _accessToken = config['mapbox']['access_token']
            _inited = True
    return _accessToken

def Request(method, urlPart, params, maxRetries = 0, retryCount = 0, responseType = 'json'):
    method = method.lower()
    url = 'https://api.mapbox.com' + urlPart + '?access_token=' + GetAccessToken()
    auth = None
    headers = {}
    if method == 'get':
        response = requests.get(url, headers=headers, params=params, auth=auth)
    # elif method == 'post':
    #     response = requests.post(url, headers=headers, data=json.dumps(params), auth=auth)
    # elif method == 'delete':
    #     response = requests.delete(url, headers=headers, data=json.dumps(params), auth=auth)

    valid = 1
    responseData = {}
    if not str(response.status_code).startswith('2'):
        log.log('warn', 'mapbox_polygon.Request bad status code', response.status_code,
            response.text, method, url, headers, params)
        valid = 0
    if responseType == 'json':
        try:
            responseData = response.json()
        except ValueError:
            valid = 0
            log.log('warn', 'mapbox_polygon.Request invalid response', response.text)
    else:
        responseData = response

    if not valid and retryCount < maxRetries:
        log.log('warn', 'mapbox_polygon.Request retrying', retryCount, maxRetries, method,
            urlPart)
        time.sleep(1)
        return Request(method, urlPart,
            params = params, maxRetries = maxRetries, retryCount = (retryCount + 1))

    return {
        'valid': valid,
        'data': responseData,
    }

def LongitudeToTile(longitude, zoom):
    return math.floor((longitude + 180)/360 * math.pow(2, zoom))

def LatitudeToTile(latitude, zoom):
    return math.floor((1 - math.log(math.tan(latitude * math.pi / 180) + 1 / math.cos(latitude * math.pi / 180)) / math.pi) / 2 * math.pow(2, zoom))

def SlippyTileToLngLat(zoom, tileX, tileY):
    n = math.pow(2, zoom)
    longitude = tileX / n * 360 - 180
    latitude = math.atan(math.sinh(math.pi * (1 - 2 * tileY / n))) * 180 / math.pi
    return [ longitude, latitude ]

def GetTileInfo(lngLat, zoom, pixelsPerTile = 256):
    tileX = LongitudeToTile(lngLat[0], zoom)
    tileY = LatitudeToTile(lngLat[1], zoom)
    lngLatTopLeft = SlippyTileToLngLat(zoom, tileX, tileY)
    metersPerPixel = MetersPerPixel(lngLatTopLeft, zoom, pixelsPerTile = pixelsPerTile)
    return { 'lngLatTopLeft': lngLatTopLeft, 'tileX': tileX, 'tileY': tileY, 'metersPerPixel': metersPerPixel,
        'zoom': zoom }

def PointToRectangleBounds(lngLat, xMeters, yMeters):
    boundsLngLat = []
    # North west (top left) = -east, -south
    lngLatDict = _math_polygon.TranslateMetersToLngLat(-xMeters / 2, -yMeters / 2, lngLat[0], lngLat[1])
    boundsLngLat.append([lngLatDict['lng'], lngLatDict['lat']])
    # North east (top right) = east, -south
    lngLatDict = _math_polygon.TranslateMetersToLngLat(xMeters / 2, -yMeters / 2, lngLat[0], lngLat[1])
    boundsLngLat.append([lngLatDict['lng'], lngLatDict['lat']])
    # South east (bottom right) = east, south
    lngLatDict = _math_polygon.TranslateMetersToLngLat(xMeters / 2, yMeters / 2, lngLat[0], lngLat[1])
    boundsLngLat.append([lngLatDict['lng'], lngLatDict['lat']])
    # South west (bottom left) = -east, south
    lngLatDict = _math_polygon.TranslateMetersToLngLat(-xMeters / 2, yMeters / 2, lngLat[0], lngLat[1])
    boundsLngLat.append([lngLatDict['lng'], lngLatDict['lat']])
    return boundsLngLat

def GetTileNumbers(boundsLngLat, zoom = None, maxMetersPerPixel = None, maxTiles = None,
    lngLatCenter = None, latExtents = 2, lngExtents = 2, pixelsPerTile = 256):
    retNumbers = { 'valid': 1, 'zoom': zoom, 'tileNumberBounds': {}, 'totalTiles': 0 }
    if lngLatCenter is not None and latExtents is not None and lngExtents is not None:
        tileLat = LatitudeToTile(lngLatCenter[1], zoom)
        tileLng = LongitudeToTile(lngLatCenter[0], zoom)
        retNumbers['tileNumberBounds'] = {
            'top': tileLat - latExtents,
            'bottom': tileLat + latExtents,
            'left': tileLng - lngExtents,
            'right': tileLng + lngExtents,
        }
        retNumbers['totalTiles'] = (latExtents * 2 + 1) * (lngExtents * 2 + 1)
    else:
        retNumbers = GetTileBounds(boundsLngLat, zoom = zoom, maxMetersPerPixel = maxMetersPerPixel,
            maxTiles = maxTiles, pixelsPerTile = pixelsPerTile)

    return retNumbers

def GetImageTiles(boundsLngLat, zoom = None, maxMetersPerPixel = None, maxTiles = None,
    lngLatCenter = None, latExtents = 2, lngExtents = 2, pixelsPerTile = 256):
    ret = { 'valid': 1, 'zoom': zoom, 'metersPerPixel': -1, 'lngLatTopLeft': [], 'img': None }

    retNumbers = GetTileNumbers(boundsLngLat, zoom = zoom, maxMetersPerPixel = maxMetersPerPixel,
        maxTiles = maxTiles, lngLatCenter = lngLatCenter, latExtents = latExtents, lngExtents = lngExtents,
        pixelsPerTile = pixelsPerTile)
    ret['totalTiles'] = retNumbers['totalTiles']
    # Zoom may have changed.
    ret['zoom'] = retNumbers['zoom']
    zoom = ret['zoom']
    retImg = GetTilesByNumbers(retNumbers['tileNumberBounds'], zoom, pixelsPerTile = pixelsPerTile)
    log.log('info', 'mapbox_polygon.GetImageTiles tile images received and joined')
    ret['img'] = retImg['img']
    ret['lngLatTopLeft'] = SlippyTileToLngLat(ret['zoom'], retNumbers['tileNumberBounds']['left'], retNumbers['tileNumberBounds']['top'])
    ret['metersPerPixel'] = MetersPerPixel(ret['lngLatTopLeft'], ret['zoom'], pixelsPerTile = pixelsPerTile)
    return ret

# https://docs.mapbox.com/data/tilesets/guides/access-elevation-data/
def GetElevationTiles(boundsLngLat, zoom = None, maxMetersPerPixel = None, maxTiles = None,
    lngLatCenter = None, latExtents = 2, lngExtents = 2, pixelsPerTile = 256):
    ret = { 'valid': 1, 'zoom': zoom, 'metersPerPixel': -1, 'lngLatTopLeft': [], 'img': None }
    retNumbers = GetTileNumbers(boundsLngLat, zoom = zoom, maxMetersPerPixel = maxMetersPerPixel,
        maxTiles = maxTiles, lngLatCenter = lngLatCenter, latExtents = latExtents, lngExtents = lngExtents,
        pixelsPerTile = pixelsPerTile)
    zoom = retNumbers['zoom']
    ret['zoom'] = retNumbers['zoom']
    ret['totalTiles'] = retNumbers['totalTiles']
    retImg = GetTilesByNumbers(retNumbers['tileNumberBounds'], zoom, tileType = 'elevation',
        pixelsPerTile = pixelsPerTile)
    log.log('info', 'mapbox_polygon.GetElevationTiles tiles received and joined')
    ret['img'] = retImg['img']
    ret['lngLatTopLeft'] = SlippyTileToLngLat(ret['zoom'], retNumbers['tileNumberBounds']['left'], retNumbers['tileNumberBounds']['top'])
    ret['metersPerPixel'] = MetersPerPixel(ret['lngLatTopLeft'], ret['zoom'], pixelsPerTile = pixelsPerTile)
    return ret

def GetVectorTiles(boundsLngLat, zoom = None, maxTiles = None,
    lngLatCenter = None, latExtents = None, lngExtents = None,
    layerTypes = [], tileType = 'street'):
    ret = { 'valid': 1, 'zoom': zoom, 'metersPerPixel': -1, 'lngLatTopLeft': [], 'jsonTiles': None }
    retNumbers = GetTileNumbers(boundsLngLat, zoom = zoom,
        maxTiles = maxTiles, lngLatCenter = lngLatCenter, latExtents = latExtents, lngExtents = lngExtents)
    zoom = retNumbers['zoom']
    ret['zoom'] = retNumbers['zoom']
    ret['totalTiles'] = retNumbers['totalTiles']
    ret['lngLatBottomLeft'] = SlippyTileToLngLat(ret['zoom'], retNumbers['tileNumberBounds']['left'], retNumbers['tileNumberBounds']['bottom'])
    ret['lngLatTopRight'] = SlippyTileToLngLat(ret['zoom'], retNumbers['tileNumberBounds']['right'], retNumbers['tileNumberBounds']['top'])
    retVector = GetVectorTilesByNumbers(retNumbers['tileNumberBounds'], zoom,
        tileType = tileType, layerTypes = layerTypes, lngLatCenter = lngLatCenter)
    log.log('info', 'mapbox_polygon.GetVectorTiles tiles received and joined')
    ret['polygons'] = retVector['polygons']
    ret['jsonTiles'] = retVector['jsonTiles']
    return ret

async def GetVectorTilesAsync(boundsLngLat, zoom = None, maxTiles = None,
    lngLatCenter = None, latExtents = None, lngExtents = None,
    layerTypes = [], tileType = 'street', onUpdate = None):
    ret = { 'valid': 1, 'zoom': zoom, 'metersPerPixel': -1, 'lngLatTopLeft': [], 'polygons': [] }
    retNumbers = GetTileNumbers(boundsLngLat, zoom = zoom,
        maxTiles = maxTiles, lngLatCenter = lngLatCenter, latExtents = latExtents, lngExtents = lngExtents)
    zoom = retNumbers['zoom']
    ret['zoom'] = retNumbers['zoom']
    ret['currentTile'] = 0
    ret['totalTiles'] = retNumbers['totalTiles']
    ret['lngLatBottomLeft'] = SlippyTileToLngLat(ret['zoom'], retNumbers['tileNumberBounds']['left'], retNumbers['tileNumberBounds']['bottom'])
    ret['lngLatTopRight'] = SlippyTileToLngLat(ret['zoom'], retNumbers['tileNumberBounds']['right'], retNumbers['tileNumberBounds']['top'])
    if onUpdate is not None:
        await onUpdate(ret)
    await GetVectorTilesByNumbersAsync(retNumbers['tileNumberBounds'], zoom,
        tileType = tileType, layerTypes = layerTypes, lngLatCenter = lngLatCenter, onUpdate = onUpdate)
    return ret

def GetTerrainWithHeightMap(lngLatCenter, xMeters, yMeters, zoom = 14, pixelsPerTile = 512,
    xVertices = None, yVertices = None, doHeightmap = 1, maxTiles = None):
    ret = { 'valid': 1, 'message': '', 'imgTerrain': None, 'imgHeightMap': None,
        'minElevationMeters': None, 'maxElevationMeters': None, 'metersPerPixel': None,
        'metersPerPixelOriginal': None, 'valuesListHeightMap': [] }

    polygonLngLats = PointToRectangleBounds(lngLatCenter, xMeters, yMeters)
    boundsLngLat = _math_polygon.MinMaxBounds(polygonLngLats)['bounds']

    # Terrain (raster tile / texture)
    retTiles = GetImageTiles(boundsLngLat, zoom = zoom, pixelsPerTile = pixelsPerTile,
        maxTiles = maxTiles)
    ret['imgTerrain'] = retTiles['img']
    ret['imgTerrainOriginal'] = retTiles['img']

    # Elevation
    if doHeightmap:
        retTilesElevation = GetElevationTiles(boundsLngLat, zoom = zoom, pixelsPerTile = pixelsPerTile)
        ret['imgHeightMap'] = retTilesElevation['img']

    ret['metersPerPixel'] = retTiles['metersPerPixel']
    # May change if / when we resize.
    ret['metersPerPixelOriginal'] = retTiles['metersPerPixel']
    lngLatTopLeft = retTiles['lngLatTopLeft']
    polygonPixels = _image_subdivide.LngLatsToPixels(polygonLngLats, lngLatTopLeft, ret['metersPerPixel'])
    boundsPixels = _math_polygon.MinMaxBounds(polygonPixels)['bounds']
    xMin = boundsPixels['min'][0]
    xMax = boundsPixels['max'][0]
    yMin = boundsPixels['min'][1]
    yMax = boundsPixels['max'][1]
    # If wanted a square, ensure pixels are square.
    xPixels = xMax - xMin
    yPixels = yMax - yMin
    if xMeters == yMeters and xPixels != yPixels:
        yPixels = xPixels
        yMax = yMin + yPixels

    # Crop
    ret['imgTerrain'] = ret['imgTerrain'][yMin:yMax, xMin:xMax]
    if doHeightmap:
        ret['imgHeightMap'] = ret['imgHeightMap'][yMin:yMax, xMin:xMax]

        # Convert to heightmap (do this AFTER crop as it can be a slow operation so want fewest / final pixels only).
        # retHeightMap = ElevationToHeightmap(ret['imgHeightMap'], minMeters = None, maxMeters = None)
        retHeightMap = ElevationToHeightmap(ret['imgHeightMap'], bits = 16)
        ret['imgHeightMap'] = retHeightMap['img']
        ret['minElevationMeters'] = retHeightMap['minElevationMeters']
        ret['maxElevationMeters'] = retHeightMap['maxElevationMeters']
        ret['elevationMetersPixelMin'] = retHeightMap['elevationMetersPixelMin']
        ret['elevationMetersPixelMax'] = retHeightMap['elevationMetersPixelMax']
        ret['valuesListHeightMap'] = retHeightMap['valuesList']

    # Resize to be at the input resolution.
    if xVertices is not None and yVertices is not None:
        ret['metersPerPixel'] *= xPixels / xVertices
        ret['imgTerrain'] = cv2.resize(ret['imgTerrain'], (xVertices, yVertices))
        if doHeightmap:
            ret['imgHeightMap'] = cv2.resize(ret['imgHeightMap'], (xVertices, yVertices))

    return ret

def GetTileBounds(boundsLngLat, zoom = None, maxMetersPerPixel = None, maxTiles = None, pixelsPerTile = 256):
    maxMetersPerPixel = maxMetersPerPixel if maxMetersPerPixel is not None else 5
    maxTiles = maxTiles if maxTiles is not None else 100
    zoom = zoom if zoom is not None else 10
    # maxTiles = maxTiles if maxTiles is not None else 250
    ret = { 'valid': 1, 'zoom': zoom, 'tileNumberBounds': {}, 'totalTiles': 0 }
    # Northern most latitude is the larger value.
    southLat = boundsLngLat['min'][1]
    northLat = boundsLngLat['max'][1]
    westLng = boundsLngLat['min'][0]
    eastLng = boundsLngLat['max'][0]
    ret['tileNumberBounds']['top'] = LatitudeToTile(northLat, zoom)
    ret['tileNumberBounds']['left'] = LongitudeToTile(westLng, zoom)
    ret['tileNumberBounds']['bottom'] = LatitudeToTile(southLat, zoom)
    ret['tileNumberBounds']['right'] = LongitudeToTile(eastLng, zoom)
    width = ret['tileNumberBounds']['right'] - ret['tileNumberBounds']['left'] + 1
    height = ret['tileNumberBounds']['bottom'] - ret['tileNumberBounds']['top'] + 1
    ret['totalTiles'] = width * height

    if ret['totalTiles'] > maxTiles:
        log.log('info', 'mapbox_polygon.GetTileBounds', ret['totalTiles'], 'above maxTiles, reducing zoom from', zoom, 'and going again')
        zoom -= 1
        return GetTileBounds(boundsLngLat, zoom, maxMetersPerPixel = -1, maxTiles = maxTiles,
            pixelsPerTile = pixelsPerTile)

    lngLatTopLeft = SlippyTileToLngLat(zoom, ret['tileNumberBounds']['left'], ret['tileNumberBounds']['top'])
    metersPerPixel = MetersPerPixel(lngLatTopLeft, zoom, pixelsPerTile = pixelsPerTile)
    if maxMetersPerPixel > 0 and metersPerPixel > maxMetersPerPixel and ret['totalTiles'] < maxTiles:
        log.log('info', 'mapbox_polygon.GetTileBounds', metersPerPixel, 'above maxMetersPerPixel', maxMetersPerPixel, ', increasing zoom from', zoom, 'and going again')
        zoom += 1
        return GetTileBounds(boundsLngLat, zoom, maxMetersPerPixel = maxMetersPerPixel, maxTiles = maxTiles,
            pixelsPerTile = pixelsPerTile)

    return ret

def GetImageTileByLngLat(zoom = 16, lngLat = [], row: int = -1, column: int = -1, tileType = 'satellite', pixelsPerTile = 512):
    ret = { 'valid': 1, 'img': None, 'tileInfo': {} }
    row = row if row >= 0 else LatitudeToTile(lngLat[1], zoom)
    column = column if column >= 0 else LongitudeToTile(lngLat[0], zoom)
    suffix = '@2x' if pixelsPerTile == 512 else ''
    # url = '/v4/mapbox.satellite/' + str(zoom) + '/' + str(column) + '/' + str(row) + '.png'
    url = '/v4/mapbox.satellite/' + str(zoom) + '/' + str(column) + '/' + str(row) + suffix + '.jpg'
    if tileType == 'elevation':
        url = '/v4/mapbox.terrain-rgb/' + str(zoom) + '/' + str(column) + '/' + str(row) + suffix + '.pngraw'
    retTile = Request('get', url, {}, responseType = '')
    bytesArray = numpy.frombuffer(retTile['data'].content, dtype = numpy.uint8)
    ret['img'] = cv2.imdecode(bytesArray, 1)
    ret['tileInfo'] = GetTileInfo(lngLat, zoom, pixelsPerTile = pixelsPerTile)
    return ret

def GetVectorTileByLngLat(zoom = 16, lngLat = [], row: int = -1, column: int = -1, tileType = 'street'):
    ret = { 'valid': 1, 'tile': {} }
    row = row if row >= 0 else LatitudeToTile(lngLat[1], zoom)
    column = column if column >= 0 else LongitudeToTile(lngLat[0], zoom)
    url = '/v4/mapbox.mapbox-streets-v8/' + str(zoom) + '/' + str(column) + '/' + str(row) + '.mvt'
    retTile = Request('get', url, {}, responseType = '')
    ret['tile'] = mapbox_vector_tile.decode(retTile['data'].content)
    # Saving lngLat bounds of each tile for reversing coordinates encodding
    ret['tile']['lngLatTopRight'] = SlippyTileToLngLat(zoom, column + 1, row)
    ret['tile']['lngLatBottomLeft'] = SlippyTileToLngLat(zoom, column, row + 1)
    lngLat = [ret['tile']['lngLatBottomLeft'][0], ret['tile']['lngLatTopRight'][1]]
    lngLatNext = [ret['tile']['lngLatTopRight'][0], ret['tile']['lngLatBottomLeft'][1]]
    offsetObj = _math_polygon.LngLatOffsetMeters(lngLatNext, lngLat)
    ret['tile']['xMeters'] = number.precision(offsetObj['offsetEastMeters'])
    ret['tile']['yMeters'] = number.precision(offsetObj['offsetSouthMeters'])
    return ret

def GetTilesByNumbers(tileNumberBounds, zoom, tileType = 'satellite', pixelsPerTile = 256):
    ret = { 'valid': 1, 'img': None }
    img = None
    row = tileNumberBounds['top']
    suffix = '@2x' if pixelsPerTile == 512 else ''
    while row <= tileNumberBounds['bottom']:
        imgRow = None
        column = tileNumberBounds['left']
        while column <= tileNumberBounds['right']:
            imgTemp = GetImageTileByLngLat(zoom = zoom, row = row, column = column, tileType = tileType, pixelsPerTile = pixelsPerTile)['img']
            # cv2.imwrite(path, imgTemp)
            if imgRow is None:
                imgRow = imgTemp
            else:
                imgRow = numpy.concatenate((imgRow, imgTemp), axis = 1)
            column += 1

        if img is None:
            img = imgRow
        else:
            img = numpy.concatenate((img, imgRow), axis = 0)
        row += 1
        log.log('info', 'mapbox_polygon.GetTilesByNumbers row', row, 'of', tileNumberBounds['bottom'], 'img.shape', img.shape)

    ret['img'] = img

    return ret

def GetVectorTilePolygons(lngLat, zoom, landTileId, layerTypes = [], lngLatCenter = None):
    mapboxTile = GetVectorTileByLngLat(zoom = zoom, lngLat = lngLat)['tile']
    return _mapbox_vector_tile.GetPolygons(mapboxTile, landTileId, layerTypes = layerTypes)

def GetVectorTilesByNumbers(tileNumberBounds, zoom, tileType = 'street',
    layerTypes = [], lngLatCenter = None, landTileId: str = ''):
    ret = { 'valid': 1, 'polygons': [], 'jsonTiles': [] }
    row = tileNumberBounds['top']
    while row <= tileNumberBounds['bottom']:
        column = tileNumberBounds['left']
        while column <= tileNumberBounds['right']:
            decodedData = GetVectorTileByLngLat(zoom = zoom, row = row, column = column)['tile']
            ret['polygons'] += _mapbox_vector_tile.GetPolygons(decodedData, landTileId, layerTypes = layerTypes)['polygons']
            # TODO - only should use polygons, so remove this?
            ret['jsonTiles'].append(decodedData)
            column += 1
        row += 1
        log.log('info', 'mapbox_polygon.GetVectorTilesByNumbers row', row, 'of', tileNumberBounds['bottom'], 'tileCount', len(ret['jsonTiles']))
    return ret

async def GetVectorTilesByNumbersAsync(tileNumberBounds, zoom, tileType = 'street',
    layerTypes = [], lngLatCenter = None, onUpdate = None, landTileId: str = ''):
    ret = { 'valid': 1, 'polygons': [], 'currentTile': 0  }
    ret['totalTiles'] = (tileNumberBounds['right'] - tileNumberBounds['left'] + 1) * \
        (tileNumberBounds['bottom'] - tileNumberBounds['top'] + 1)
    row = tileNumberBounds['top']
    while row <= tileNumberBounds['bottom']:
        column = tileNumberBounds['left']
        while column <= tileNumberBounds['right']:
            decodedData = GetVectorTileByLngLat(zoom = zoom, row = row, column = column)['tile']
            ret['polygons'] = _mapbox_vector_tile.GetPolygons(decodedData, landTileId, layerTypes = layerTypes)['polygons']
            ret['currentTile'] += 1
            if onUpdate is not None:
                await onUpdate(ret)
            column += 1
        row += 1
        log.log('info', 'mapbox_polygon.GetVectorTilesByNumbersAsync row', row, 'of',
            tileNumberBounds['bottom'], 'currentTile', ret['currentTile'], 'totalTiles', ret['totalTiles'])

def MetersPerPixel(lngLat, zoom, pixelsPerTile = 256):
    earthRadiusMeters = 6378137
    circumference = 2 * math.pi * earthRadiusMeters
    metersPerTile = circumference * math.cos(lngLat[1] * math.pi / 180) / math.pow(2, zoom)
    metersPerPixel = metersPerTile / pixelsPerTile
    return metersPerPixel

def GetElevation(R, G, B):
    return -10000 + ((R * 256 * 256 + G * 256 + B) * 0.1)

# Dead sea is -420m, Mt. Everest is 8848m. Lowest point in sea is about -11k.
# https://stackoverflow.com/questions/8818206/16-bit-grayscale-png
# https://stackoverflow.com/questions/59666299/create-save-16-bits-rgb-image-with-opencv
def ElevationToHeightmap(image, minMeters = -1000, maxMeters = 9000, bits = 8):
    if bits not in [8,16]:
        bits = 8
    ret = { 'valid': 1, 'message': '', 'img': None, 'minElevationMeters': None, 'maxElevationMeters': None,
        'elevationMetersPixelMin': minMeters, 'elevationMetersPixelMax': maxMeters,
        'valuesList': [] }
    maxPixelValue = 2**bits - 1
    minElevationMeters = None
    maxElevationMeters = None
    # imageHeightmap = None
    print ('shape', image.shape)
    height = image.shape[0]
    width = image.shape[1]
    elevations = []
    for y in range(0, height):
        elevations.append([])
        for x in range(0, width):
            color = image[y, x]
            # opencv / numpy store in bgr order: https://stackoverflow.com/questions/12187354/get-rgb-value-opencv-python
            elevation = number.precision(GetElevation(color[2], color[1], color[0]))
            if minElevationMeters is None or elevation < minElevationMeters:
                minElevationMeters = elevation
            if maxElevationMeters is None or elevation > maxElevationMeters:
                maxElevationMeters = elevation
            # Store elevation.
            elevations[y].append(elevation)

    if minMeters is None:
        minMeters = minElevationMeters
        ret['elevationMetersPixelMin'] = minMeters
    if maxMeters is None:
        maxMeters = maxElevationMeters
        ret['elevationMetersPixelMax'] = maxMeters
    # elevationRange = maxElevationMeters - minElevationMeters
    # Go through a second time, this time setting the pixels as a multiple of the min / max elevation.
    imageOut = None
    if bits == 16:
        imageOut = numpy.zeros((height, width, 1)).astype(numpy.uint16)
    else:
        imageOut = numpy.zeros((height, width, 1))

    for y in range(0, height):
        ret['valuesList'].append([])
        for x in range(0, width):
            val = round(RangeValue(elevations[y][x], minMeters, maxMeters, 0, maxPixelValue))
            ret['valuesList'][y].append(val)
            imageOut[y, x] = val
            # xResized = round(x * 2017 / width)
            # yResized = round(y * 2017 / height)
            # if (xResized >= 1060 and xResized <= 1100 and yResized >= 730 and yResized <= 770):
            #     print (xResized, yResized, val, elevations[y][x])

    # Ensure / convert to grayscale
    # image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    ret['img'] = imageOut
    ret['minElevationMeters'] = minElevationMeters
    ret['maxElevationMeters'] = maxElevationMeters
    return ret

def RangeValue(value, valueMin, valueMax, newStart, newEnd):
    if value <= valueMin:
        return newStart
    elif value >= valueMax:
        return newEnd
    else:
        changeRatio = abs((value - valueMin) / (valueMax - valueMin))
        return newStart + (newEnd - newStart) * changeRatio
