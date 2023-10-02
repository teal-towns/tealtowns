import mongomock

import log
import ml_config
import mongo_db

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
