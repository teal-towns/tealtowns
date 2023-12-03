# from fastapi import APIRouter

from common import socket as _socket
from vector_tiles import vector_tiles as _vector_tiles
from vector_tiles import vector_tiles_data as _vector_tiles_data

# router = APIRouter()

def AddRoutes():
    def GetLandTiles(data, auth, websocket):
        xCount = data['xCount'] if 'xCount' in data else None
        yCount = data['yCount'] if 'yCount' in data else None
        zoom = data['zoom'] if 'zoom' in data else None
        ret = _vector_tiles_data.GetTiles(data['timeframe'], data['year'], data['latCenter'],
            data['lngCenter'], xCount = xCount, yCount = yCount, zoom = zoom)
        return ret
    _socket.add_route('getLandTiles', GetLandTiles)

    def GetVectorTiles(data, auth, websocket):
        lngLat = [float(data['lng']), float(data['lat'])]
        return _vector_tiles.GetVectorTiles(lngLat, float(data['xMeters']),
            float(data['yMeters']))
    _socket.add_route('get-vector-tiles-sync', GetVectorTiles)

    def SaveLandTile(data, auth, websocket):
        valid = 1
        requiredFields = ['timeframe', 'year', 'zoom', 'tile']
        for field in requiredFields:
            if field not in data:
                ret = { 'valid': 0, 'msg': 'Missing required fields' }
                valid = 0
                break
        if valid:
            ret = _vector_tiles_data.SaveTile(data['timeframe'], data['year'], data['zoom'],
                data['tile'])
        return ret
    _socket.add_route('saveLandTile', SaveLandTile)

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
