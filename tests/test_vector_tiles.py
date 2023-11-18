from vector_tiles import vector_tiles as _vector_tiles

import mongo_mock as _mongo_mock

_mongo_mock.InitAllCollections()

def test_GetVectorTiles():
    lngLatCenter = [-122.033802, 37.977362]
    xMeters = 125
    yMeters = 125
    ret = _vector_tiles.GetVectorTiles(lngLatCenter, xMeters, yMeters)
    print ('ret polygons', len(ret['polygons']),ret['polygons'])
