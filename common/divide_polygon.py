import geopandas
from shapely import wkt
from shapely.ops import linemerge, unary_union, polygonize

from common import mapbox_polygon as _mapbox_polygon
from common import math_polygon as _math_polygon

# Find all road classes & descriptions -> https://docs.mapbox.com/data/tilesets/reference/mapbox-streets-v8/#road
def GetStreetLinesFromMapbox(polygonDataFrame, includeRoadClasses=None):
    bounds = polygonDataFrame.total_bounds
    boundsLngLat = {
        'min': [bounds[0], bounds[1]],
        'max': [bounds[2], bounds[3]]
    }
    ret = _mapbox_polygon.GetStreetTiles(boundsLngLat)

    jsonTiles = ret['jsonTiles']
    roadsLineStrings = []
    roadClasses = set()  # Not used for now but can be useful for future
    for tile in jsonTiles:
        lngLatTopRight = tile['lngLatTopRight']
        lngLatBottomLeft = tile['lngLatBottomLeft']
        if 'road' in tile.keys():
            extent = tile['road']['extent']
            for feature in tile['road']['features']:
                roadClasses.add(feature['properties']['class'])
                if includeRoadClasses == None or feature['properties']['class'] in includeRoadClasses:
                    # Convert to lng, lat coords
                    for idx, coordinates in enumerate(feature['geometry']['coordinates']):
                        if feature['geometry']['type'] == 'LineString':
                            # need to debug the converted lng lats are off, roads are bigger than actual
                            lngLat = _math_polygon.MapboxTileBaseCoordToLatLng(
                                coordinates[0], coordinates[1], lngLatTopRight, lngLatBottomLeft, extent)
                            feature['geometry']['coordinates'].remove(
                                coordinates)
                            feature['geometry']['coordinates'].insert(
                                idx, [lngLat['lng'], lngLat['lat']])
                        elif feature['geometry']['type'] == 'MultiLineString':
                            for idx, coord in enumerate(coordinates):
                                lngLat = _math_polygon.MapboxTileBaseCoordToLatLng(
                                    coord[0], coord[1], lngLatTopRight, lngLatBottomLeft, extent)
                                coordinates.remove(coord)
                                coordinates.insert(
                                    idx, [lngLat['lng'], lngLat['lat']])
                else:
                    tile['road']['features'].remove(feature)
            line = geopandas.GeoDataFrame.from_features(
                tile['road']['features'])
            roadsLineStrings.extend(line.geometry)
    return roadsLineStrings

def DividePolygonByPolygon(plotPolygon, objectPolygon):
    newPolygons = []
    intersection = plotPolygon.overlay(objectPolygon, how='intersection')
    difference1 = plotPolygon.overlay(objectPolygon, how='difference')

    newPolygons.append(intersection)
    newPolygons.append(difference1)
    return newPolygons

def DividePolygonByMergedLines(polygon, lines):
    polygon = wkt.loads(str(polygon.geometry.iloc[0]))
    line = wkt.loads(str(lines.geometry.iloc[0]))
    lineList = []
    for line in lines.geometry:
        lineList.append(wkt.loads(str(line)))
    merged = linemerge([polygon.boundary, *lineList])
    borders = unary_union(merged)
    polygons = polygonize(borders)
    divided = []
    for p in polygons:
        # adding a tiny buffer to the polygon so that the boarders don't touch to effectively use "contain"
        if polygon.contains(p.buffer(-1e-10)):
            divided.append(p)
    dividedPolygons = geopandas.GeoDataFrame(geometry=divided)
    return dividedPolygons