# from fastapi import APIRouter

from common import socket as _socket
from vector_tiles import vector_tiles as _vector_tiles
from vector_tiles import vector_tiles_data as _vector_tiles_data
from vector_tiles import land_tile_polygon as _land_tile_polygon

# router = APIRouter()

def AddRoutes():
    def GetLandTiles(data, auth, websocket):
        xCount = data['xCount'] if 'xCount' in data else None
        yCount = data['yCount'] if 'yCount' in data else None
        zoom = data['zoom'] if 'zoom' in data else None
        timeframe = data['timeframe'] if 'timeframe' in data else ''
        year = data['year'] if 'year' in data else ''
        autoInsert = data['autoInsert'] if 'autoInsert' in data else 0
        ret = _vector_tiles_data.GetTiles(data['latCenter'],
            data['lngCenter'], timeframe = timeframe, year = year, xCount = xCount, yCount = yCount,
            zoom = zoom, autoInsert = autoInsert)
        return ret
    _socket.add_route('getLandTiles', GetLandTiles)

    def GetVectorTiles(data, auth, websocket):
        lngLat = [float(data['lng']), float(data['lat'])]
        return _vector_tiles.GetVectorTiles(lngLat, float(data['xMeters']),
            float(data['yMeters']))
    _socket.add_route('get-vector-tiles-sync', GetVectorTiles)

    def SaveLandTile(data, auth, websocket):
        valid = 1
        requiredFields = ['zoom', 'tile']
        for field in requiredFields:
            if field not in data:
                ret = { 'valid': 0, 'message': 'Missing required fields' }
                valid = 0
                break
        if valid:
            timeframe = data['timeframe'] if 'timeframe' in data else ''
            year = data['year'] if 'year' in data else ''
            ret = _vector_tiles_data.SaveTile(data['zoom'], data['tile'], timeframe, year)
        return ret
    _socket.add_route('saveLandTile', SaveLandTile)

    def GetLandTilePolygon(data, auth, websocket):
        types = data['typesString'].split(',') if 'typesString' in data and len(data['typesString']) > 0 else []
        shapes = data['shapesString'].split(',') if 'shapesString' in data and len(data['shapesString']) > 0 else []
        clearCache = data['clearCache'] if 'clearCache' in data else 0
        return _land_tile_polygon.GetLandTilePolygon(data['landTileId'], types, shapes, clearCache = clearCache)
    _socket.add_route('GetLandTilePolygon', GetLandTilePolygon)

def AddRoutesAsync():
    async def GetVectorTilesAsync(data, auth, websocket):
        async def OnUpdate(data):
            await _socket.sendAsync(websocket, "get-vector-tiles", data, auth)

        lngLat = [float(data['lng']), float(data['lat'])]
        return await _vector_tiles.GetVectorTilesAsync(lngLat, float(data['xMeters']),
            float(data['yMeters']), onUpdate = OnUpdate)
    _socket.add_route('get-vector-tiles', GetVectorTilesAsync, 'async')


AddRoutes()
AddRoutesAsync()
