import copy
import math


# _earthRadiusMeters = 6378137
_earthRadiusMeters = 6371009

# https://stackoverflow.com/a/4682656/1429106
# verticesLngLat is [lng, lat, altitude] format, e.g. [ -80.199481507059502, 7.43519489149553, 0.0 ]
# Returns vertices in meters.
def SinusoidalProject(verticesLngLat):
    global _earthRadiusMeters
    earthRadiusMeters = _earthRadiusMeters
    latDist = math.pi * earthRadiusMeters / 180.0

    vertices = []
    for point in verticesLngLat:
        lat = point[1]
        lng = point[0]
        x = lng * latDist * math.cos(math.radians(lat))
        y = lat * latDist
        vertices.append([x, y])
    return vertices

# https://www.omnicalculator.com/math/irregular-polygon-area#how-to-find-the-area-of-an-irregular-polygon-shoelace-theorem
def PolygonArea(vertices2D):
    sum1 = 0
    totVertices = len(vertices2D)
    for ii, point in enumerate(vertices2D):
        indexNext = ii + 1 if ii < totVertices - 1 else 0
        vertexNext = vertices2D[indexNext]
        sum1 += vertices2D[ii][0] * vertexNext[1] - vertices2D[ii][1] * vertexNext[0]
    area = sum1 * 0.5
    if area < 0:
        area = area * -1
    return area

# Returns area in square meters.
# Testing online: https://geographiclib.sourceforge.io/cgi-bin/Planimeter?type=polygon&rhumb=geodesic&input=42.77600431068023+-91.91064970397949%0D%0A42.74512614726864+-91.93588392639161%0D%0A42.75256351983369+-91.84250013732878%0D%0A42.773232206518266+-91.8409551849362&option=Submit
# https://www.earthpoint.us/shapes.aspx
def PolygonAreaLngLat(verticesLngLat):
    vertices = SinusoidalProject(verticesLngLat)
    return PolygonArea(vertices)

def PolygonsAreaHaLngLat(polygonsVerticesLngLat):
    area = 0
    for verticesLngLat in polygonsVerticesLngLat:
        area += PolygonAreaLngLat(verticesLngLat)
    areaHa = area/10000.0
    return areaHa

def MinMaxBounds(verticesLngLat):
    ret = { 'bounds': { 'min': copy.deepcopy(verticesLngLat[0]), 'max': copy.deepcopy(verticesLngLat[0]) } }
    for vertex in verticesLngLat:
        if vertex[0] < ret['bounds']['min'][0]:
            ret['bounds']['min'][0] = vertex[0]
        if vertex[1] < ret['bounds']['min'][1]:
            ret['bounds']['min'][1] = vertex[1]
        if vertex[0] > ret['bounds']['max'][0]:
            ret['bounds']['max'][0] = vertex[0]
        if vertex[1] > ret['bounds']['max'][1]:
            ret['bounds']['max'][1] = vertex[1]
    return ret

# https://gis.stackexchange.com/questions/2951/algorithm-for-offsetting-a-latitude-longitude-by-some-amount-of-meters
# Assumes flat earth; accurate to 10 meters within 200 to 2000 meters offset.
def TranslateMetersToLngLat(offsetEastMeters, offsetSouthMeters, lngOrigin, latOrigin):
    global _earthRadiusMeters
    earthRadiusMeters = _earthRadiusMeters
    # Start with radians
    offsetLat = -1 * offsetSouthMeters / earthRadiusMeters
    offsetLng = offsetEastMeters / (earthRadiusMeters * math.cos(latOrigin * math.pi / 180))
    # Convert to degrees
    lat = latOrigin + offsetLat * 180 / math.pi
    lng = lngOrigin + offsetLng * 180 / math.pi
    return { 'lat': lat, 'lng': lng }

def LngLatOffsetMeters(lngLat, lngLatOrigin):
    global _earthRadiusMeters
    earthRadiusMeters = _earthRadiusMeters

    offsetLat = (lngLat[1] - lngLatOrigin[1]) / 180 * math.pi
    offsetLng = (lngLat[0] - lngLatOrigin[0]) / 180 * math.pi
    offsetSouthMeters = -1 * offsetLat * earthRadiusMeters
    offsetEastMeters = offsetLng * (earthRadiusMeters * math.cos(lngLatOrigin[1] * math.pi / 180))

    return { 'offsetEastMeters': offsetEastMeters, 'offsetSouthMeters': offsetSouthMeters }

# Todo: resolve duplicate methods & remove below 2 functions
def TranslateMetersToLngLatBottomLeft(offsetEastMeters, offsetNorthMeters, lngOrigin, latOrigin):
    global _earthRadiusMeters
    earthRadiusMeters = _earthRadiusMeters
    # Start with radians
    offsetLat = offsetNorthMeters / earthRadiusMeters
    offsetLng = offsetEastMeters / (earthRadiusMeters * math.cos(latOrigin * math.pi / 180))
    # Convert to degrees
    lat = latOrigin + offsetLat * 180 / math.pi
    lng = lngOrigin + offsetLng * 180 / math.pi
    return { 'lat': lat, 'lng': lng }

def LngLatOffsetMetersBottomLeft(lngLat, lngLatOrigin):
    global _earthRadiusMeters
    earthRadiusMeters = _earthRadiusMeters

    offsetLat = (lngLat[1] - lngLatOrigin[1]) / 180 * math.pi
    offsetLng = (lngLat[0] - lngLatOrigin[0]) / 180 * math.pi
    offsetNorthMeters = offsetLat * earthRadiusMeters
    offsetEastMeters = offsetLng * (earthRadiusMeters * math.cos(lngLatOrigin[1] * math.pi / 180))

    return { 'offsetEastMeters': offsetEastMeters, 'offsetNorthMeters': offsetNorthMeters }

def PolygonCenter2D(polygonLngLats):
    numPoints = len(polygonLngLats)
    xSum = 0
    ySum = 0
    for point in polygonLngLats:
        xSum += point[0]
        ySum += point[1]
    lngLatCenter = [xSum / numPoints, ySum / numPoints]
    return lngLatCenter

def PolygonCenter(verticesXYZ):
    numPoints = len(verticesXYZ)
    xSum = 0
    ySum = 0
    zSum = 0
    for point in verticesXYZ:
        xSum += point[0]
        ySum += point[1]
        zSum += point[2]
    return [xSum / numPoints, ySum / numPoints, zSum / numPoints]

# def geojsonCentroid(filePath):
#     df = geopandas.read_file(filePath).dissolve()
#     df['centroid'] = df['geometry'].centroid
#     lng = df.centroid.map(lambda p: p.x)
#     lat = df.centroid.map(lambda p: p.y)
#     return lng, lat

# https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon
# def IsPointInPolygon(lngLat, polygonLngLats) {
#     inside = 0;
#     pointsCount = len(polygonLngLats)
    # TODO
#     for i = 0, j = pointsCount - 1; i < pointsCount; j = i++:
#         if (polygonLngLats[i][0] > lngLat[0]) != (polygonLngLats[j][0] > lngLat[0]) and \
#             lngLat[1] < (polygonLngLats[j][1] - polygonLngLats[i][1]) * (lngLat[0] - polygonLngLats[i][0]) /
#             (polygonLngLats[j][0] - polygonLngLats[i][0]) + polygonLngLats[i][1]:
#             inside = not inside;
#     }
#     return inside
