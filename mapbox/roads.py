import geopandas
from shapely.geometry import Polygon

import lodash
from common import divide_polygon as _divide_polygon
from common import math_polygon as _math_polygon

def GetRoadsForPolygon(vertices, projectLng, projectLat, includeRoadClasses = None):
    polygonDataFrame = PolygonVerticesToGeopandasPolygon(vertices, projectLng, projectLat)
    roadsLineStringsFromTiles = _divide_polygon.GetStreetLinesFromMapbox(polygonDataFrame, includeRoadClasses)
    roadsDataFrame = geopandas.GeoDataFrame(geometry=roadsLineStringsFromTiles)
    roadsInPolygon = geopandas.overlay(roadsDataFrame, polygonDataFrame, how = 'intersection')
    # Use explode to convert any MultiLineStrings to LineStrings only
    roadsInPolygonLineString = roadsInPolygon.explode()
    maxY = max([vertex['y'] for vertex in vertices])
    roads = LinesDataFrameToRoads(roadsInPolygonLineString, [projectLng, projectLat], maxY)
    return roads

def LinesDataFrameToRoads(dataFrame, lngLatOrigin, maxY):
    roads = []
    for _, line in dataFrame.iterrows():
        road = {}
        road['vertices'] = []
        coordinates = line['geometry'].coords
        for coords in coordinates:
            offsets = _math_polygon.LngLatOffsetMetersBottomLeft(coords, lngLatOrigin)
            road['vertices'].append(
                {'x': offsets['offsetEastMeters'], 'y': maxY, 'z': offsets['offsetNorthMeters']})
        roads.append(road)
    return roads

def PolygonVerticesToGeopandasPolygon(polygonVertices, lngOrigin, latOrigin):
    lngPoints = []
    latPoints = []
    for vertex in polygonVertices:
        lngLat = _math_polygon.TranslateMetersToLngLatBottomLeft(vertex['x'], vertex['z'], lngOrigin, latOrigin)
        lngPoints.append(lngLat['lng'])
        latPoints.append(lngLat['lat'])
    polygonGeometry = Polygon(zip(lngPoints, latPoints))
    polygon = geopandas.GeoDataFrame(index=[0], crs='epsg:4326', geometry=[polygonGeometry])
    return polygon

def GeopandasPolygonToPolygon(polygonDataFrame, lngLatOrigin, maxY):
    ret = { 'valid': 1, 'polygons': [] }
    for _, polygonDF in polygonDataFrame.iterrows():
        polygon = {}
        polygon['uName'] = 'Polygon_' + lodash.random_string()
        polygon['vertices'] = []
        coordinates = polygonDF['geometry'].exterior.coords
        for coords in coordinates:
            offsets = _math_polygon.LngLatOffsetMetersBottomLeft(coords, lngLatOrigin)
            polygon['vertices'].append({'x': offsets['offsetEastMeters'], 'y': maxY, 'z': offsets['offsetSouthMeters']})
        posCenterCoords = polygonDF['geometry'].centroid
        posCenterXZ = _math_polygon.LngLatOffsetMetersBottomLeft([posCenterCoords.x, posCenterCoords.y], lngLatOrigin)
        polygon['posCenter'] = {'x': posCenterXZ['offsetEastMeters'], 'y': maxY, 'z': posCenterXZ['offsetSouthMeters']}
        ret['polygons'].append(polygon)
    return ret

def DividePolygonByRoads(vertices, projectLng, projectLat):
    maxY = max([vertex['y'] for vertex in vertices])
    polygonGeoDataFrame = PolygonVerticesToGeopandasPolygon(vertices, projectLng, projectLat)
    roadsInPolygonTiles = _divide_polygon.GetStreetLinesFromMapbox(polygonGeoDataFrame)
    roads = geopandas.GeoDataFrame(geometry=roadsInPolygonTiles)
    roads = geopandas.GeoDataFrame.explode(roads)
    dividedPolygons = _divide_polygon.DividePolygonByMergedLines(polygonGeoDataFrame, roads)
    polygons = GeopandasPolygonToPolygon(dividedPolygons, [projectLng, projectLat], maxY)
    # TODO
    # ret = SaveBulk(polygons)
    # return ret