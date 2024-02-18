# We store tiles (10m x 10m) which is 67 million tiles for the Earth, but for 30% land cover is 20 million.
# We store tiles for each year, for 3 types: 1. actual (current year), 2. past (10 years), 3. future (30 years).
# Thus to start we have 1 actual year (current year), 10 past years, 30 future predicted years = 41 databases of up to 20 million tiles (documents) each.
# Each new year we will add another actual year and another future year (2 new databases).
# We can then compare last year's future predicted year to the current actual year, compare, and use that to improve our model / predictions.
# We fill in data many ways:
# 1. manual:
# a. expert deep dives
# b. mobile app input (current state)
# 2. automated:
# a. existing other datasets (e.g. Google Earth Engine)
# b. computer vision (current & past state)
# c. predictive models (future state)
# d. mobile app (current state).
# We fill in data as needed; if a tile is requested and does not exist yet, we create a new empty tile.
# We can run scripts to fill (or update) data.

import math
import json

from mapbox import mapbox_polygon as _mapbox_polygon
from common import math_polygon as _math_polygon
from common import image_subdivide as _image_subdivide
import lodash
import mongo_db
import number
from vector_tiles import vector_tiles_databases as _vector_tiles_databases

# Returns tiles as 2D list of rows and columns.


def GetTiles(timeframe, year, latCenter, lngCenter, xCount=None, yCount=None, zoom=None,
             autoInsert=0):
    zoom = int(zoom) if zoom is not None else 16
    xCount = int(xCount) if xCount is not None else 32
    yCount = int(yCount) if yCount is not None else 32
    # Maximums
    if xCount > 32:
        xCount = 32
    if yCount > 32:
        yCount = 32
    ret = {'valid': 1, 'message': '', 'tileRows': []}
    tileNumberCenterY = _mapbox_polygon.LatitudeToTile(latCenter, zoom)
    tileNumberCenterX = _mapbox_polygon.LongitudeToTile(lngCenter, zoom)
    tileNumberTop = tileNumberCenterY - math.floor(yCount / 2)
    tileNumberLeft = tileNumberCenterX - math.floor(xCount / 2)
    tileNumberBottom = tileNumberTop + yCount - 1
    tileNumberRight = tileNumberLeft + xCount - 1
    database = _vector_tiles_databases.GetDatabase(timeframe, year, zoom)
    query = {
        'tileX': {'$gte': tileNumberLeft, '$lte': tileNumberRight},
        'tileY': {'$gte': tileNumberTop, '$lte': tileNumberBottom},
        'tileZoom': zoom,
    }
    sort = {'tileY': 1, 'tileX': 1}
    tiles = mongo_db.find(
        'landTile', query, sort_obj=sort, db1=database)['items']

    # If any missing tiles, create them.
    tilesPerRow = math.pow(2, zoom)
    totalTiles = xCount * yCount
    if len(tiles) < totalTiles:
        tilesToInsert = []
        currentY = tileNumberTop
        row = 0
        tileIndex = 0
        noTiles = 1 if len(tiles) < 1 else 0
        tileY = tiles[tileIndex]['tileY'] if len(tiles) > 0 else -1
        tileX = tiles[tileIndex]['tileX'] if len(tiles) > 0 else -1
        while currentY <= tileNumberBottom:
            currentX = tileNumberLeft
            ret['tileRows'].append([])
            while currentX <= tileNumberRight:
                if tileY == currentY and tileX == currentX:
                    ret['tileRows'][row].append(tiles[tileIndex])
                    tileIndex += 1
                    if tileIndex < len(tiles):
                        tileY = tiles[tileIndex]['tileY']
                        tileX = tiles[tileIndex]['tileX']
                    else:
                        tileY = -1
                        tileX = -1
                else:
                    tile = NewTile(zoom, currentX, currentY)
                    if autoInsert:
                        tilesToInsert.append(tile)
                    ret['tileRows'][row].append(tile)
                currentX += 1
            currentY += 1
            row += 1
        if len(tilesToInsert) > 0:
            mongo_db.insert_many('landTile', tilesToInsert, db1=database)
    elif len(tiles) > 0:
        currentY = -1
        row = -1
        for index, tile in enumerate(tiles):
            tileY = tile['tileY']
            # New row
            if currentY != tileY:
                currentY = tileY
                ret['tileRows'].append([])
                row += 1
            ret['tileRows'][row].append(tile)

    return ret


def NewTile(zoom, tileX, tileY):
    tilesPerRow = math.pow(2, zoom)
    lngLat = _mapbox_polygon.SlippyTileToLngLat(zoom, tileX, tileY)
    lngLatNext = _mapbox_polygon.SlippyTileToLngLat(zoom, tileX + 1, tileY + 1)
    offsetObj = _math_polygon.LngLatOffsetMeters(lngLatNext, lngLat)
    tile = {
        'tileX': tileX,
        'tileY': tileY,
        'tileZoom': int(zoom),
        'tileNumber': int((tileY - 1) * tilesPerRow + tileX),
        'xMeters': number.precision(offsetObj['offsetEastMeters']),
        'yMeters': number.precision(offsetObj['offsetSouthMeters']),
        'latTopLeft': number.precision(lngLat[1], '.000001'),
        'lngTopLeft': number.precision(lngLat[0], '.000001'),
        'elevations': [],
    }
    return tile


def TileXYToNumber(tileX, tileY, zoom, tilesPerRow=None):
    tilesPerRow = tilesPerRow if tilesPerRow is not None else math.pow(2, zoom)
    return int((tileY - 1) * tilesPerRow + tileX)


def SaveTile(timeframe, year, zoom, tile):
    ret = {'valid': 1, 'message': '', 'tile': {}}

    database = _vector_tiles_databases.GetDatabase(timeframe, year, zoom)
    if '_id' not in tile:
        if 'tileX' not in tile or 'tileY' not in tile:
            ret['valid'] = 0
            ret['message'] = 'vector_tiles_data.SaveTile either _id or (tileX and tileY) are required'
            return ret

        # Look up just in case
        query = {
            'tileX': tile['tileX'],
            'tileY': tile['tileY'],
            'tileZoom': zoom,
        }
        fields = {'_id': 1, }
        tileCheck = mongo_db.find_one('landTile', query, db1=database)['item']
        if tileCheck is not None:
            tile['_id'] = tileCheck['_id']

    if '_id' in tile:
        query = {
            '_id': mongo_db.to_object_id(tile['_id'])
        }
        saveVals = lodash.omit(tile, ['_id', 'createdAt', 'updatedAt', 'tileX', 'tileY',
            'tileZoom', 'tileNumber', 'xMeters', 'yMeters', 'latTopLeft', 'lngTopLeft'])
        mutation = {
            '$set': saveVals,
        }
        # nonNestedFields = ['elevationTopLeftMeters', 'country', 'state', 'ecozone',
        #     'slopeDegreesAverage']
        # mutation = {
        #     '$set': {}
        # }
        # for field in saveVals:
        #     if field in nonNestedFields:
        #         mutation['$set'][field] = saveVals[field]
        #     else:
        #         key = field + '.' +
        #         mutation['$set']
        result = mongo_db.update_one('landTile', query, mutation, db1=database)
    else:
        tileDefault = NewTile(zoom, tile['tileX'], tile['tileY'])
        for key in tileDefault:
            tile[key] = tileDefault[key]
        result = mongo_db.insert_one('landTile', tile, db1=database)['item']
        tile['_id'] = mongo_db.from_object_id(result['_id'])
    print('result', result, database, tile)
    if result:
        ret['tile'] = tile
    else:
        ret['valid'] = 0

    return ret


def GetTileById(timeframe, year, zoom, tileId):
    ret = {'valid': 1, 'message': '', 'tile': {}}
    database = _vector_tiles_databases.GetDatabase(timeframe, year, zoom)
    query = {
        '_id': mongo_db.to_object_id(tileId),
    }
    ret['tile'] = mongo_db.find_one('landTile', query, db1=database)['item']
    return ret


def InsertTreeLocsInTiles(timeframe, year, lngLatOrigin,  pixelOffsets, zoom, metersPerPixel):
    pointLngLats = _image_subdivide.PixelsToLngLats(pixelOffsets, lngLatOrigin, metersPerPixel):
    _id = 1
    uName = 'mapbox_' + 'tree' + '_' + str(_id)
    polygon = {
        '_id': uName,
        'uName': uName,
        'vertices': pointLngLats,
        'posCenter': '',
        'type': 'tree',
        'shape': 'point',
        'pairsString': '',
        'source': 'mapbox'
     }
    ret = GetTiles(timeframe, year, lngLatOrigin[1], lngLatOrigin[0], xCount=1, yCount=1, zoom=zoom,
             autoInsert=0)
    ret['polygon'] = polygon
    return ret
   
