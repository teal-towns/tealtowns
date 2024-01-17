import random

# from common import mongo_db_crud as _mongo_db_crud
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
        return _nameDefaultsMap[collectionName]
    return {}

def CreateBulk(objs: list[dict] = [], default: dict = {}, base: dict = {}, collectionName = '', count = 1,
    saveInDatabase = 1):
    if len(objs) < 1:
        objs = []
        for i in range(0, count):
            objs.append({})
    if len(base) < 1 and len(collectionName) > 0:
        base = GetDefaultFromCollectionName(collectionName)

    newDefault = lodash.extend_object(base, default)
    newObjs = []
    for obj in objs:
        newObjs.append(lodash.extend_object(newDefault, obj))
    if len(collectionName) > 0 and saveInDatabase:
        newObjs = mongo_db.insert_many(collectionName, newObjs)['items']
    return newObjs
