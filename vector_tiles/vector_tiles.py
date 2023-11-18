from common import math_polygon as _math_polygon
from mapbox import mapbox_polygon as _mapbox_polygon

def GetVectorTiles(lngLatCenter, xMeters, yMeters):
    zoom = 16
    polygonLngLats = _mapbox_polygon.PointToRectangleBounds(lngLatCenter, xMeters, yMeters)
    boundsLngLat = _math_polygon.MinMaxBounds(polygonLngLats)['bounds']
    retTiles = _mapbox_polygon.GetVectorTiles(boundsLngLat, zoom = zoom,
        lngLatCenter = lngLatCenter)
    return retTiles
