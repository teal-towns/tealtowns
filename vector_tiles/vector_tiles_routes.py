from vector_tiles import vector_tiles as _vector_tiles
import routes_websocket

def AddRoutes():
    def GetVectorTiles(data, auth):
        lngLat = [float(data['lng']), float(data['lat'])]
        return _vector_tiles.GetVectorTiles(lngLat, float(data['xMeters']),
            float(data['yMeters']))
    routes_websocket.AddRoute('get-vector-tiles', GetVectorTiles)

AddRoutes()
