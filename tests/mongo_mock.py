import mongomock

import log
import ml_config
import mongo_db

from vector_tiles import vector_tiles_databases as _vector_tiles_databases
_databasesLandTiles = {}

_db = {}
_inited = 0

def InitAllCollections():
    global _inited
    global _db
    if not _inited:
        collectionNames = ['user', 'image']
        for collectionName in collectionNames:
            _db[collectionName] = mongomock.MongoClient().db.collection
        mongo_db.SetDB(_db)

        InitAllLandTiles()

        # Init other core things too.
        config = ml_config.get_config()
        log.init_logger(config)

        _inited = 1

def GetCollection(collectionName):
    global _db
    if collectionName in _db:
        return _db[collectionName]
    _db[collectionName] = mongomock.MongoClient().db.collection
    mongo_db.SetDB(_db)
    return _db[collectionName]

def CleanUp():
    DeleteAll()

def DeleteAll(collectionKeys = None):
    if collectionKeys is None:
        collectionKeys = ['user', 'image']
    for key in collectionKeys:
        mongo_db.delete_many(key, {})
    
    DeleteAllLandTiles()

def InitAllLandTiles(mode = 'init'):
    global _databasesLandTiles
    collectionNames = ['landTile']

    zoom = 16

    timeframe = 'actual'
    for year in range(2023, 2023 + 1):
        databaseName = 'vectorTiles_' + str(zoom) + '_' + timeframe + '_' + str(year)
        if mode == 'init':
            _databasesLandTiles[databaseName] = {}
        for collectionName in collectionNames:
            if mode == 'delete':
                mongo_db.delete_many(collectionName, {}, db1 = _databasesLandTiles[databaseName])
            else:
                _databasesLandTiles[databaseName][collectionName] = mongomock.MongoClient().db.collection
        if mode == 'init':
            _vector_tiles_databases.SetDatabase(databaseName, _databasesLandTiles[databaseName])

    # timeframe = 'past'
    # for year in range(2012, 2022 + 1):
    #     databaseName = 'vectorTiles_' + str(zoom) + '_' + timeframe + '_' + str(year)
    #     if mode == 'init':
    #         _databasesLandTiles[databaseName] = {}
    #     for collectionName in collectionNames:
    #         if mode == 'delete':
    #             mongo_db.delete_many(collectionName, {}, db1 = _databasesLandTiles[databaseName])
    #         else:
    #             _databasesLandTiles[databaseName][collectionName] = mongomock.MongoClient().db.collection
    #     if mode == 'init':
    #         _vector_tiles_databases.SetDatabase(databaseName, _databasesLandTiles[databaseName])

    # timeframe = 'future'
    # for year in range(2024, 2054 + 1):
    #     databaseName = 'vectorTiles_' + str(zoom) + '_' + timeframe + '_' + str(year)
    #     if mode == 'init':
    #         _databasesLandTiles[databaseName] = {}
    #     for collectionName in collectionNames:
    #         if mode == 'delete':
    #             mongo_db.delete_many(collectionName, {}, db1 = _databasesLandTiles[databaseName])
    #         else:
    #             _databasesLandTiles[databaseName][collectionName] = mongomock.MongoClient().db.collection
    #     if mode == 'init':
    #         _vector_tiles_databases.SetDatabase(databaseName, _databasesLandTiles[databaseName])

    # timeframe = 'futureBest'
    # for year in range(2024, 2054 + 1):
    #     databaseName = 'vectorTiles_' + str(zoom) + '_' + timeframe + '_' + str(year)
    #     if mode == 'init':
    #         _databasesLandTiles[databaseName] = {}
    #     for collectionName in collectionNames:
    #         if mode == 'delete':
    #             mongo_db.delete_many(collectionName, {}, db1 = _databasesLandTiles[databaseName])
    #         else:
    #             _databasesLandTiles[databaseName][collectionName] = mongomock.MongoClient().db.collection
    #     if mode == 'init':
    #         _vector_tiles_databases.SetDatabase(databaseName, _databasesLandTiles[databaseName])

def DeleteAllLandTiles():
    InitAllLandTiles(mode = 'delete')
