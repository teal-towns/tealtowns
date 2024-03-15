from common import mongo_db_crud as _mongo_db_crud
import date_time
from land_vision.urban_tree_detection import urban_trees as _urban_trees
from mapbox import mapbox_polygon as _mapbox_polygon
import mongo_db
from vector_tiles import vector_tiles_databases as _vector_tiles_databases
from vector_tiles import vector_tiles_data as _vector_tiles_data

def GetLandTilePolygon(landTileId: str, types: list = [], shapes: list = [], zoom: int = 16,
    limit: int = 10000, clearCache: int = 0):
    ret = { 'newInsertCountsBySource': {} }
    database = _vector_tiles_databases.GetDatabase(zoom)
    # See if need to get any sources.
    sourceTypes = {
        'tree': ['urbanTrees'],
        'building': ['mapbox_building'],
    }
    # fields = { 'cachedSources': 1, 'xMeters': 1, 'yMeters': 1, }
    fields = None
    retTile = _mongo_db_crud.GetById('landTile', landTileId, db1 = database, fields = fields)
    landTile = retTile['landTile']
    if clearCache:
        landTile['cachedSources'] = {}
        mongo_db.delete_many('landTilePolygon', {'landTileId': landTileId}, db1 = database)
    needToUpdate = 0
    lngLatTileCenter = _vector_tiles_data.GetTileCenter(landTile)
    for sourceType in sourceTypes:
        for source in sourceTypes[sourceType]:
            if source not in landTile['cachedSources']:
                if source == 'urbanTrees':
                    retTrees = _urban_trees.GetTreesPolygons(landTileId = landTileId, zoom = zoom, clearCache = clearCache)
                    ret['newInsertCountsBySource'][source] = len(retTrees['landTilePolygons'])
                    landTile['cachedSources'][source] = date_time.now_string()
                    needToUpdate = 1
                elif source == 'mapbox_building':
                    retPolygons = _mapbox_polygon.GetVectorTilePolygons(lngLatTileCenter, zoom, landTileId,
                        layerTypes = ['building'])
                    if len(retPolygons['polygons']) > 0:
                        retInsert = InsertPolygons(retPolygons['polygons'], database)
                        ret['newInsertCountsBySource'][source] = retInsert['insertCount']
                        # mongo_db.insert_many('landTilePolygon', retPolygons['polygons'], db1 = database)
                    landTile['cachedSources'][source] = date_time.now_string()
                    needToUpdate = 1
    if needToUpdate:
        query = { '_id': mongo_db.to_object_id(landTileId) }
        mutation = { '$set': { 'cachedSources': landTile['cachedSources'] } }
        mongo_db.update_one('landTile', query, mutation, db1 = database)

    listKeyVals = {}
    if len(types) > 0:
        listKeyVals['type'] = types
    if len(shapes) > 0:
        listKeyVals['shape'] = shapes
    retPolygons = _mongo_db_crud.Search('landTilePolygon', {'landTileId': landTileId}, listKeyVals = listKeyVals,
        db1 = database, limit = limit)
    retPolygons['newInsertCountsBySource'] = ret['newInsertCountsBySource']
    retPolygons['landTileId'] = landTileId
    return retPolygons

def InsertPolygons(polygons: list, database):
    uNames = []
    for polygon in polygons:
        uNames.append(polygon['uName'])
    fields = { 'uName': 1, }
    landPolygons = mongo_db.find('landTilePolygon', { 'uName': { '$in': uNames } }, fields=fields, db1 = database)['items']
    uNamesFound = []
    for landPolygon in landPolygons:
        uNamesFound.append(landPolygon['uName'])
    for index, polygon in reversed(list(enumerate(polygons))):
        if polygon['uName'] in uNamesFound:
            del polygons[index]
    if len(polygons) > 0:
        mongo_db.insert_many('landTilePolygon', polygons, db1 = database)
    return { 'valid': 1, 'message': '', 'insertCount': len(polygons) }
