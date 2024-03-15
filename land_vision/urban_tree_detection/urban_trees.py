import lodash
import mongo_db
from common import data_convert as _data_convert
from common import image_subdivide as _image_subdivide
from common import math_polygon as _math_polygon
from common import mongo_db_crud as _mongo_db_crud
from land_vision.urban_tree_detection import evaluate as _urban_trees_evaluate
from mapbox import mapbox_polygon as _mapbox_polygon
from vector_tiles import vector_tiles_data as _vector_tiles_data
from vector_tiles import vector_tiles_databases as _vector_tiles_databases

def GetTreesByLngLat(lngLat, pixelsPerTile = 512):
    ret = { 'lngLats': [] }
    retImage = _mapbox_polygon.GetImageTileByLngLat(lngLat = lngLat, pixelsPerTile = pixelsPerTile)
    tileInfo = retImage['tileInfo']
    retTrees = _urban_trees_evaluate.GetTrees(images = [retImage['img']])
    pixels = retTrees['pixels']
    ret['lngLats'] = _image_subdivide.PixelsToLngLats(pixels, tileInfo['lngLatTopLeft'], tileInfo['metersPerPixel'])
    ret['tileInfo'] = tileInfo

    return ret

def GetTreesPolygons(lngLat: list = [], landTileId: str = '', zoom = 16, pixelsPerTile = 512, clearCache: int = 0,
    lngLatTopLeft: list = []):
    ret = { 'valid': 1, 'message': '', 'landTilePolygons': [] }
    source = 'urbanTrees'
    # First check database.
    tile = None
    if landTileId == '':
        retTiles = _vector_tiles_data.GetTiles(lngLat[1], lngLat[0], zoom = zoom, xCount = 1, yCount = 1, autoInsert=1)
        tile = retTiles['tileRows'][0][0]
        landTileId = tile['_id']
    database = _vector_tiles_databases.GetDatabase(zoom)
    if clearCache:
        mongo_db.delete_many('landTilePolygon', {'landTileId': landTileId, 'source': source}, db1 = database)
    if not clearCache:
        retPolygons = _mongo_db_crud.Search('landTilePolygon', {'landTileId': landTileId, 'source': source},
            db1 = database)
        if len(retPolygons['landTilePolygons']) > 0:
            return retPolygons

    if lngLat == [] or lngLatTopLeft == []:
        if tile is None:
            retTile = _mongo_db_crud.GetById('landTile', landTileId, db1 = database)
            tile = retTile['landTile']
        if lngLat == []:
            lngLat = _vector_tiles_data.GetTileCenter(tile)
        if lngLatTopLeft == []:
            lngLatTopLeft = [tile['lngTopLeft'], tile['latTopLeft']]
    retTrees = GetTreesByLngLat(lngLat, pixelsPerTile = pixelsPerTile)
    lngLats = retTrees['lngLats']
    tileInfo = retTrees['tileInfo']
    tileNumber = _vector_tiles_data.GetTileNumber(tileInfo['zoom'], tileInfo['tileX'], tileInfo['tileY'])
    polygons = []
    layerType = 'tree'
    for lngLat1 in lngLats:
        uName = 'urbanTree_' + str(tileNumber) + '_' + lodash.random_string(5)
        retOffset = _math_polygon.LngLatOffsetMeters(lngLat1, lngLatTopLeft)
        vertex = [retOffset['offsetEastMeters'], retOffset['offsetSouthMeters'], 0]
        polygons.append(
            {
                '_id': uName,
                'landTileId': landTileId,
                'uName': uName,
                'vertices': _data_convert.VerticesToStrings([vertex]),
                'posCenter': _data_convert.VertexToString(vertex),
                'type': layerType,
                'shape': 'point',
                'pairsString': '',
                'source': 'urbanTrees',
            }
        )
    
    mongo_db.insert_many('landTilePolygon', polygons, db1 = database)
    ret['landTilePolygons'] = polygons

    return ret
