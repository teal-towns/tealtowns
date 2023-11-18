from common import data_convert as _data_convert
from common import math_polygon as _math_polygon

# https://docs.mapbox.com/data/tilesets/reference/mapbox-streets-v8/#building
# classesByType = {
#     'road': ['primary', 'secondary', 'tertiary']
# }
def GetPolygons(tile, layerTypes = ['building', 'road', 'water'], classesByType = {},
    lngLatCenter = None):
    ret = { 'valid': 1, 'polygons': [] }
    shapeMap = {
        'Point': 'point',
        'MultiPoint': 'point',
        'LineString': 'path',
        'MultiLineString': 'path',
        'Polygon': 'polygon',
        'MultiPolygon': 'polygon',
    }
    lngLatTopRight = tile['lngLatTopRight']
    lngLatBottomLeft = tile['lngLatBottomLeft']
    for layerType in layerTypes:
        if layerType in tile.keys():
            extent = tile[layerType]['extent']
            for feature in tile[layerType]['features']:
                # roadClasses.add(feature['properties']['class'])
                if layerType not in classesByType or len(classesByType[layerType]) == 0 or \
                    feature['properties']['class'] in classesByType[layerType]:
                    uName = 'mapbox_' + layerType + '_' + str(feature['id'])
                    polygon = {
                        '_id': uName,
                        'uName': uName,
                        'vertices': [],
                        'posCenter': '',
                        'type': layerType,
                        'shape': shapeMap[feature['geometry']['type']],
                        'pairsString': '',
                        'source': 'mapbox',
                    }
                    # TODO - add pairsString (varies by layerType, etc.)
                    # TODO - handle points?
                    # TODO - handle multi polygon?
                    if feature['geometry']['type'] not in ['Point', 'MultiPoint', 'MultiPolygon']:
                        # Convert to lng, lat coords
                        for idx, coordinates in enumerate(feature['geometry']['coordinates']):
                            # print ('coordinates', coordinates, 'shape', polygon['shape'], feature['geometry']['type'])
                            if feature['geometry']['type'] in ['Polygon', 'MultiPolygon', 'MultiLineString']:
                                for idx, coord in enumerate(coordinates):
                                    # print ('coord', coord, coord[0], coord[1])
                                    lngLat = MapboxTileBaseCoordToLngLat(coord[0], coord[1],
                                        lngLatTopRight, lngLatBottomLeft, extent)
                                    retOffset = _math_polygon.LngLatOffsetMeters(lngLat, lngLatCenter)
                                    polygon['vertices'].append([-1 * retOffset['offsetSouthMeters'], retOffset['offsetEastMeters'], 0])
                            elif feature['geometry']['type'] in ['LineString']:
                                # need to debug the converted lng lats are off, roads are bigger than actual
                                lngLat = MapboxTileBaseCoordToLngLat(coordinates[0], coordinates[1],
                                    lngLatTopRight, lngLatBottomLeft, extent)
                                retOffset = _math_polygon.LngLatOffsetMeters(lngLat, lngLatCenter)
                                polygon['vertices'].append([-1 * retOffset['offsetSouthMeters'], retOffset['offsetEastMeters'], 0])
                        polygon['posCenter'] = _data_convert.VertexToString(_math_polygon.PolygonCenter(polygon['vertices']))
                        polygon['vertices'] = _data_convert.VerticesToStrings(polygon['vertices'])
                        ret['polygons'].append(polygon)
    return ret

# Reverse of mapbox tile base coordinate encoding: https://github.com/tilezen/mapbox-vector-tile#coordinate-transformations-for-encoding
def MapboxTileBaseCoordToLngLat(xTileCoord, yTileCoord, lngLatTopRight, lngLatBottomLeft, extent):
    minLat = lngLatBottomLeft[1]
    minLng = lngLatBottomLeft[0]
    latSpan = lngLatTopRight[1] - lngLatBottomLeft[1]
    lngSpan = lngLatTopRight[0] - lngLatBottomLeft[0]
    lngLat = [ xTileCoord * lngSpan / extent + minLng, yTileCoord * latSpan / extent + minLat ]
    return lngLat
