# We store tiles (10m x 10m) which is 67 million tiles for the Earth, but for 30% land cover is 20 million.
# We store tiles for each year, for 3 types: 1. actual (current year), 2. past (10 years), 3. future (30 years).
# Thus to start we have 1 actual year (current year), 10 past years, 30 future predicted years = 41 databases of up to 20 million tiles (documents) each.
# Each new year we will add another actual year and another future year (2 new databases).
# We can then compare last year's future predicted year to the current actual year, compare, and use that to improve our model / predictions.
# We fill in data many ways:
# 1. manual:
# a. expert deep dives
# b. mobile app input (current state)
# 2. automated:
# a. existing other datasets (e.g. Google Earth Engine)
# b. computer vision (current & past state)
# c. predictive models (future state)
# d. mobile app (current state).
# We fill in data as needed; if a tile is requested and does not exist yet, we create a new empty tile.
# We can run scripts to fill (or update) data.

import pymongo

import log
import mongo_db
import ml_config

_config = ml_config.get_config()

_databases = {}

def GetDatabase(zoom, timeframe = '', year = ''):
    global _databases
    databaseName = 'vectorTiles_' + str(zoom)
    if len(timeframe) > 0:
        databaseName += '_' + timeframe
    if len(str(year)) > 0:
        databaseName += '_' + str(year)
    # print ('databaseName', databaseName)
    if databaseName not in _databases:
        if 'mongodb' in _config and 'url' in _config['mongodb']:
            timeframeKey = timeframe if len(timeframe) > 0 else 'actual'
            key = 'url_vector_tiles_' + timeframeKey
            if key in _config['mongodb']:
                mdb_client = mongo_db.get_client(_config['mongodb'][key])
                _databases[databaseName] = mdb_client[databaseName]
                # _databases[databaseName]['landTile'].drop()
                _databases[databaseName]['landTile'].create_index([('tileX', pymongo.ASCENDING), \
                    ('tileY', pymongo.ASCENDING), ('tileZoom', pymongo.ASCENDING)], unique = True)
                _databases[databaseName]['landTile'].create_index([('tileNumber', 1)], unique = False)

                # _databases[databaseName]['landTilePolygon'].drop_indexes()
                # _databases[databaseName]['landTilePolygon'].drop()
                _databases[databaseName]['landTilePolygon'].create_index([('uName', 1)], unique = True)
                _databases[databaseName]['landTilePolygon'].create_index([('landTileId', 1),
                    ('type', 1), ('shape', 1), ('source', 1)], unique = False)
            else:
                log.log('warn', 'vector_tiles_databases.GetDatabaseName missing config for key', key, databaseName)
                return None
    return _databases[databaseName]

def SetDatabase(databaseName, db):
    global _databases
    _databases[databaseName] = db
