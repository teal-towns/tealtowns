from common import math_polygon as _math_polygon
from mapbox import mapbox_polygon as _mapbox_polygon

def GetVectorTiles(lngLatCenter, xMeters, yMeters):
    zoom = 16
    polygonLngLats = _mapbox_polygon.PointToRectangleBounds(lngLatCenter, xMeters, yMeters)
    boundsLngLat = _math_polygon.MinMaxBounds(polygonLngLats)['bounds']
    retTiles = _mapbox_polygon.GetVectorTiles(boundsLngLat, zoom = zoom,
        lngLatCenter = lngLatCenter)
    return retTiles

async def GetVectorTilesAsync(lngLatCenter, xMeters, yMeters, onUpdate = None):
    zoom = 16
    polygonLngLats = _mapbox_polygon.PointToRectangleBounds(lngLatCenter, xMeters, yMeters)
    boundsLngLat = _math_polygon.MinMaxBounds(polygonLngLats)['bounds']
    ret = await _mapbox_polygon.GetVectorTilesAsync(boundsLngLat, zoom = zoom,
        lngLatCenter = lngLatCenter, onUpdate = onUpdate)
    return ret
