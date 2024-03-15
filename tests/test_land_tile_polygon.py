import mongo_mock as _mongo_mock
from vector_tiles import land_tile_polygon as _land_tile_polygon
from vector_tiles import vector_tiles_data as _vector_tiles_data

_mongo_mock.InitAllCollections()

def test_GetLandTilePolygon():
    # First get (create) land tiles.
    lngLat = [-122.033715, 37.973167]
    zoom = 16
    ret = _vector_tiles_data.GetTiles(lngLat[1], lngLat[0], xCount = 2, yCount = 2, zoom = zoom, autoInsert = 1)

    landTile = ret['tileRows'][0][0]
    landTileId = landTile['_id']
    ret = _land_tile_polygon.GetLandTilePolygon(landTileId)
    assert len(ret['landTilePolygons']) > 0
    newInserts = 0
    for source in ret['newInsertCountsBySource']:
        newInserts += ret['newInsertCountsBySource'][source]
    assert newInserts > 0
    
    # Should be cached the second time.
    ret = _land_tile_polygon.GetLandTilePolygon(landTileId)
    assert len(ret['landTilePolygons']) > 0
    newInserts = 0
    for source in ret['newInsertCountsBySource']:
        newInserts += ret['newInsertCountsBySource'][source]
    assert newInserts == 0
