import math
import geopandas

from common import math_polygon as _math_polygon
from mapbox import mapbox_polygon as _mapbox_polygon
from vector_tiles import vector_tiles_data as _vector_tiles_data
import number

from common import upload_coordinates


def GetPolygonFileTilesInfo(filePath):
    ret = {'valid': 1, 'message': '', 'bounds': {},
           'areaHa': -1, 'tileNumbersZoom16': [], }
    geoDataFrame = geopandas.read_file(filePath)
    geoDataFrame = geoDataFrame
    bounds = geoDataFrame.total_bounds
    precision = '.00001'
    ret['bounds'] = {
        'min': [number.precision(bounds[0], precision), number.precision(bounds[1], precision), 0, ],
        'max': [number.precision(bounds[2], precision), number.precision(bounds[3], precision), 0, ],
    }

    # areas = geoDataFrame.area
    # print ('areas', areas)
    areaMeters = 0
    geojson = upload_coordinates.geoDataFrameToGeojson(geoDataFrame)
    ret1 = upload_coordinates.GeojsonToParcels(geojson)
    for parcel in ret1['parcels']:
        areaMeters += float(
            _math_polygon.PolygonAreaLngLat(parcel['coordinates']))
    areaHa = number.precision(float(areaMeters / 10000), '.001')
    ret['areaHa'] = areaHa

    # Get tile numbers bounds.
    zoom = 16
    tileNumberMinY = _mapbox_polygon.LatitudeToTile(
        ret['bounds']['min'][0], zoom)
    tileNumberMinX = _mapbox_polygon.LongitudeToTile(
        ret['bounds']['min'][1], zoom)
    tileNumberMaxY = _mapbox_polygon.LatitudeToTile(
        ret['bounds']['max'][0], zoom)
    tileNumberMaxX = _mapbox_polygon.LongitudeToTile(
        ret['bounds']['max'][1], zoom)
    if tileNumberMinY > tileNumberMaxY:
        minCopy = tileNumberMinY
        tileNumberMinY = tileNumberMaxY
        tileNumberMaxY = minCopy
    if tileNumberMinX > tileNumberMaxX:
        minCopy = tileNumberMinX
        tileNumberMinX = tileNumberMaxX
        tileNumberMaxX = minCopy

    tileY = tileNumberMinY
    tilesPerRow = math.pow(2, zoom)
    while tileY <= tileNumberMaxY:
        tileX = tileNumberMinX
        while tileX <= tileNumberMaxX:
            lngLat = _mapbox_polygon.SlippyTileToLngLat(zoom, tileX, tileY)
            point = geopandas.points_from_xy(x=[lngLat[0]], y=[lngLat[1]])
            if len(geoDataFrame['geometry'].contains(point[0])) > 0:
                tileNumber = _vector_tiles_data.TileXYToNumber(tileX, tileY, zoom,
                                                               tilesPerRow=tilesPerRow)
                ret['tileNumbersZoom16'].append(tileNumber)
            tileX += 1
        tileY += 1

    return ret
