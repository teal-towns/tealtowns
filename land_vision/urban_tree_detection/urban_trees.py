import lodash
import mongo_db
from common import image_subdivide as _image_subdivide
from common import mongo_db_crud as _mongo_db_crud
from land_vision.urban_tree_detection import evaluate as _urban_trees_evaluate
from mapbox import mapbox_polygon as _mapbox_polygon
from vector_tiles import vector_tiles_data as _vector_tiles_data
from vector_tiles import vector_tiles_databases as _vector_tiles_databases

def GetTreesByLngLat(lngLat, pixelsPerTile = 512):
    ret = { 'lngLats': [] }
    retImage = _mapbox_polygon.GetImageTileByLngLat(lngLat, pixelsPerTile = pixelsPerTile)
    tileInfo = retImage['tileInfo']
    retTrees = _urban_trees_evaluate.GetTrees(images = [retImage['img']])
    pixels = retTrees['pixels']
    ret['lngLats'] = _image_subdivide.PixelsToLngLats(pixels, tileInfo['lngLatTopLeft'], tileInfo['metersPerPixel'])
    ret['tileInfo'] = tileInfo

    return ret

def GetTreesPolygons(lngLat, zoom = 16, pixelsPerTile = 512):
    source = 'urbanTrees'
    # First check database.
    retTiles = _vector_tiles_data.GetTiles(lngLat[1], lngLat[0], zoom = zoom, xCount = 1, yCount = 1, autoInsert=1)
    tile = retTiles['tileRows'][0][0]
    landTileId = tile['_id']
    database = _vector_tiles_databases.GetDatabase(zoom)
    retPolygons = _mongo_db_crud.Search('landTilePolygon', {'landTileId': landTileId, 'source': source},
        db1 = database)
    if len(retPolygons['landTilePolygons']) > 0:
        return retPolygons

    retTrees = GetTreesByLngLat(lngLat, pixelsPerTile = pixelsPerTile)
    lngLats = retTrees['lngLats']
    tileInfo = retTrees['tileInfo']
    tileNumber = _vector_tiles_data.GetTileNumber(tileInfo['zoom'], tileInfo['tileX'], tileInfo['tileY'])
    polygons = []
    layerType = 'tree'
    for lngLat in lngLats:
        uName = 'urbanTree_' + str(tileNumber) + '_' + lodash.random_string(5)
        polygons.append(
            {
                '_id': uName,
                'landTileId': landTileId,
                'uName': uName,
                'vertices': [lngLat],
                'posCenter': lngLat,
                'type': layerType,
                'shape': 'point',
                'pairsString': '',
                'source': 'urbanTrees',
            }
        )
    
    mongo_db.insert_many('landTilePolygon', polygons, db1 = database)

    return { 'valid': 1, 'message': '', 'landTilePolygons': polygons }
