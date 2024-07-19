import random

import copy

# from common import mongo_db_crud as _mongo_db_crud
import date_time
import lodash
import mongo_db

_nameDefaultsMap = {}

def RandomString(length = 10, charsType = 'full'):
    return lodash.random_string(length, charsType)

def RandomWord(wordMin = 2, wordMax = 10):
    return RandomString(random.randint(wordMin, wordMax))

def RandomWords(count = 5, wordMin = 2, wordMax = 10):
    words = ''
    for i in range(0, count):
        words += RandomWord(wordMin, wordMax) + ' '
    return words

def RandomTime():
    return str(random.randint(0, 23)).zfill(2) + ':' + str(random.randint(0, 59)).zfill(2)

def RandomDateTime():
    now = date_time.now()
    year = random.randint(now.year - 1, now.year)
    month = random.randint(1, 12)
    day = random.randint(1, 28)
    hour = random.randint(0, 23)
    minute = random.randint(0, 59)
    return date_time.string(date_time.create(year, now.month, now.day, hour, minute))

def RandomPhone():
    return "+1" + str(random.randint(1000000000, 9999999999))

def RandomImageUrl():
    return RandomString() + '.jpg'

def RandomLocation():
    return { 'type': 'Point', 'coordinates': [ round(random.uniform(-180, 180), 3), round(random.uniform(-90, 90), 3) ] }

def AddToNameMap(collectionName: str, defaults: dict):
    global _nameDefaultsMap
    _nameDefaultsMap[collectionName] = defaults

def GetDefaultFromCollectionName(collectionName: str):
    # nameMap = {
    #     'sharedItem': _stubs_shared_item.GetDefault(),
    #     'sharedItemOwner': _stubs_shared_item_owner.GetDefault(),
    #     'user': _stubs_user.GetDefault(),
    # }
    if collectionName in _nameDefaultsMap:
        return _nameDefaultsMap[collectionName]()
    return {}

def CreateBulk(objs: list = [], default: dict = {}, base: dict = {}, collectionName: str = '', count: int = 1,
    saveInDatabase: int = 1):
    if len(objs) < 1:
        objs = []
        for i in range(0, count):
            objs.append({})
    newObjs = []
    for obj in objs:
        newBase = {}
        if len(base) < 1 and len(collectionName) > 0:
            newBase = GetDefaultFromCollectionName(collectionName)
        else:
            newBase = copy.deepcopy(base)
        newDefault = lodash.extend_object(newBase, default)
        newObjs.append(lodash.extend_object(newDefault, obj))
    if len(collectionName) > 0 and saveInDatabase:
        newObjs = mongo_db.insert_many(collectionName, newObjs)['items']
    return newObjs
