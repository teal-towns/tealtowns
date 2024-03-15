from common import data_convert as _data_convert
from common import math_polygon as _math_polygon

# https://docs.mapbox.com/data/tilesets/reference/mapbox-streets-v8/#building
# classesByType = {
#     'road': ['primary', 'secondary', 'tertiary']
# }
def GetPolygons(mapboxTile, landTileId, layerTypes = [], classesByType = {}):
    layerTypes = layerTypes if layerTypes is not [] else ['building', 'road', 'water']
    ret = { 'valid': 1, 'polygons': [] }
    shapeMap = {
        'Point': 'point',
        'MultiPoint': 'point',
        'LineString': 'path',
        'MultiLineString': 'path',
        'Polygon': 'polygon',
        'MultiPolygon': 'polygon',
    }
    lngLatTopRight = mapboxTile['lngLatTopRight']
    lngLatBottomLeft = mapboxTile['lngLatBottomLeft']
    lngLatTopLeft = [ lngLatBottomLeft[0], lngLatTopRight[1] ]
    for layerType in layerTypes:
        if layerType in mapboxTile.keys():
            extent = mapboxTile[layerType]['extent']
            for feature in mapboxTile[layerType]['features']:
                # roadClasses.add(feature['properties']['class'])
                if layerType not in classesByType or len(classesByType[layerType]) == 0 or \
                    feature['properties']['class'] in classesByType[layerType]:
                    uName = 'mapbox_' + layerType + '_' + str(feature['id'])
                    source = 'mapbox' + '_' + layerType
                    polygon = {
                        # '_id': uName,
                        'uName': uName,
                        'landTileId': landTileId,
                        'vertices': [],
                        'posCenter': '',
                        'type': layerType,
                        'shape': shapeMap[feature['geometry']['type']],
                        'pairsString': '',
                        'source': source,
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
                                    retOffset = _math_polygon.LngLatOffsetMeters(lngLat, lngLatTopLeft)
                                    polygon['vertices'].append([retOffset['offsetEastMeters'], retOffset['offsetSouthMeters'], 0])
                            elif feature['geometry']['type'] in ['LineString']:
                                # need to debug the converted lng lats are off, roads are bigger than actual
                                lngLat = MapboxTileBaseCoordToLngLat(coordinates[0], coordinates[1],
                                    lngLatTopRight, lngLatBottomLeft, extent)
                                retOffset = _math_polygon.LngLatOffsetMeters(lngLat, lngLatTopLeft)
                                polygon['vertices'].append([retOffset['offsetEastMeters'], retOffset['offsetSouthMeters'], 0])
                        posCenter = _math_polygon.PolygonCenter(polygon['vertices'])
                        # Ensure in this tile.
                        if posCenter[0] >= 0 and posCenter[0] <= mapboxTile['xMeters'] and \
                            posCenter[1] >= 0 and posCenter[1] <= mapboxTile['yMeters']:
                            polygon['posCenter'] = _data_convert.VertexToString(posCenter)
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
