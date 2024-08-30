import mongomock

import log
import ml_config
import mongo_db
import notifications

from notifications_all import email_sendgrid as _email_sendgrid
from notifications_all import sms_twilio as _sms_twilio
from pay_mercury import pay_mercury as _pay_mercury
from user import user_availability as _user_availability
from user import user_interest as _user_interest

from stubs import stubs_event as _stubs_event
from stubs import stubs_mercury_pay_out as _stubs_mercury_pay_out
from stubs import stubs_neighborhood as _stubs_neighborhood
from stubs import stubs_shared_item as _stubs_shared_item
from stubs import stubs_shared_item_owner as _stubs_shared_item_owner
from stubs import stubs_user as _stubs_user
from stubs import stubs_user_availability as _stubs_user_availability
from stubs import stubs_user_event as _stubs_user_event
from stubs import stubs_user_feedback as _stubs_user_feedback
from stubs import stubs_user_insight as _stubs_user_insight
from stubs import stubs_user_interest as _stubs_user_interest
from stubs import stubs_user_neighborhood as _stubs_user_neighborhood
from stubs import stubs_user_neighborhood_weekly_update as _stubs_user_neighborhood_weekly_update
from stubs import stubs_weekly_event as _stubs_weekly_event

from vector_tiles import vector_tiles_databases as _vector_tiles_databases
_databasesLandTiles = {}

_db = {}
_inited = 0
_initedLive = 0
_collectionNames = ['user', 'image', 'blog',
    'weeklyEvent', 'event', 'userWeeklyEvent', 'userEvent',
    'sharedItem', 'sharedItemOwner',
    'userMoney', 'userPayment', 'userPaymentSubscription', 'userStripeAccount', 'mercuryPayOut',
    'neighborhood', 'userNeighborhood', 'neighborhoodGroup', 'userNeighborhoodWeeklyUpdate',
    'certificationLevel', 'journeyStep', 'neighborhoodCertificationLevel', 'neighborhoodJourneyStep',
    'userMessage',
    'eventFeedback', 'userFeedback',
    'neighborhoodStatsMonthlyCache', 'eventInsight',
    'icebreaker',
    'appInsight', 'userInsight', 'userFollowUp',
    'userInterest', 'userAvailability',
]

def InitLive():
    global _initedLive
    if not _initedLive:
        config = ml_config.get_config()
        log.init_logger(config)
        db = ml_config.get_db(config)
        config_notifications = config['notifications'] or {}
        notifications.set_config(config_notifications)

        _initedLive = 1


def InitAllCollections():
    global _inited
    global _db
    if not _inited:
        collectionNames = _collectionNames
        for collectionName in collectionNames:
            _db[collectionName] = mongomock.MongoClient().db.collection
        mongo_db.SetDB(_db)

        InitAllLandTiles()

        # Init other core things too.
        config = ml_config.get_config()
        log.init_logger(config)

        _stubs_event.AddDefault()
        _stubs_mercury_pay_out.AddDefault()
        _stubs_neighborhood.AddDefault()
        _stubs_shared_item.AddDefault()
        _stubs_shared_item_owner.AddDefault()
        _stubs_user.AddDefault()
        _stubs_user_availability.AddDefault()
        _stubs_user_event.AddDefault()
        _stubs_user_feedback.AddDefault()
        _stubs_user_insight.AddDefault()
        _stubs_user_interest.AddDefault()
        _stubs_user_neighborhood.AddDefault()
        _stubs_user_neighborhood_weekly_update.AddDefault()
        _stubs_weekly_event.AddDefault()

        _sms_twilio.SetTestMode(1)
        _email_sendgrid.SetTestMode(1)
        _pay_mercury.SetTestMode(1)
        _user_availability.SetTestMode(1)
        _user_interest.SetTestMode(1)

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
        collectionKeys = _collectionNames
    for key in collectionKeys:
        mongo_db.delete_many(key, {})
    
    DeleteAllLandTiles()

def InitAllLandTiles(mode = 'init'):
    global _databasesLandTiles
    collectionNames = ['landTile', 'landTilePolygon']

    zoom = 16

    databaseName = 'vectorTiles_' + str(zoom)
    if mode == 'init':
        _databasesLandTiles[databaseName] = {}
    for collectionName in collectionNames:
        if mode == 'delete':
            mongo_db.delete_many(collectionName, {}, db1 = _databasesLandTiles[databaseName])
        else:
            _databasesLandTiles[databaseName][collectionName] = mongomock.MongoClient().db.collection
    if mode == 'init':
        _vector_tiles_databases.SetDatabase(databaseName, _databasesLandTiles[databaseName])

    # timeframe = 'actual'
    # for year in range(2023, 2023 + 1):
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
