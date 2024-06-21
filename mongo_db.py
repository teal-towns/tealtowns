import pymongo
from bson.objectid import ObjectId
import json
import ssl

import lodash
import mongo_db_indices
import date_time

_db = None
_dbSchema = None

def CleanId(obj: dict):
    if '_id' in obj and (not obj['_id'] or len(obj['_id']) == 0):
        del obj['_id']
    return obj

def HaveId(obj: dict):
    if '_id' in obj and obj['_id'] and len(obj['_id']) > 0:
        return True
    return False

def map_object_id_to_string(obj1):
    obj1['_id'] = from_object_id(obj1['_id'])
    return obj1

def newObjectIdString():
    return str(ObjectId())

def from_object_id(id):
    return str(id)

def to_object_id(id):
    return ObjectId(id)

def ToObjectIds(ids):
    objectIds = []
    for id1 in ids:
        objectIds.append(to_object_id(id1))
    return objectIds

def FromObjectIds(objectIds):
    ids = []
    for objectId in objectIds:
        ids.append(from_object_id(objectId))
    return ids

def sort_to_list(sort_obj):
    if sort_obj is None:
        return None
    sort = []
    for key in sort_obj:
        direction = pymongo.DESCENDING if sort_obj[key] < 0 else pymongo.ASCENDING
        sort.append((key, direction))
    return sort

def get_client(db_url):
    return pymongo.MongoClient(db_url, ssl=True, tlsAllowInvalidCertificates=True)

def SetDB(db):
    global _db
    _db = db

def get_db(db_name, mdb_client):
    global _db

    # Only initialize once.
    if _db is not None:
        return _db

    _db = mdb_client[db_name]
    mongo_db_indices.create_all_indices(_db)
    return _db

def db_default(db = None):
    if db is not None:
        return db
    return _db

def connect_to_db(db_url, db_name):
    mdb_client = get_client(db_url)
    return get_db(db_name, mdb_client)

def get_collection(collection_name, db1 = None):
    db = db_default(db1)
    return db[collection_name]

# CRUD helpers
def insert_one(collection_name, obj1, db1 = None, validate: int = 1, allowPartial: int = 0):
    ret = { 'valid': 1, 'message': '', 'item': {}, }
    db = db_default(db1)
    collection = get_collection(collection_name, db)

    if validate:
        retCheck = Validate(collection_name, obj1, allowPartial = allowPartial)
        if not retCheck['valid']:
            ret['valid'] = retCheck['valid']
            ret['message'] = retCheck['message']
            return ret

    # Add timestamp
    obj1['createdAt'] = date_time.now_string()
    obj1['updatedAt'] = date_time.now_string()
    # obj = lodash.extend_object({
    #     'createdAt': date_time.now_string()
    # }, obj1);

    inserted_id = from_object_id(collection.insert_one(obj1).inserted_id)
    ret['item'] = lodash.extend_object(obj1, {
        '_id': inserted_id
    })
    return ret

def insert_many(collection_name, objects, db1 = None, validate: int = 1, allowPartial: int = 0):
    ret = { 'valid': 1, 'message': '', 'items': [], }
    db = db_default(db1)
    collection = get_collection(collection_name, db)

    if validate:
        for obj in objects:
            retCheck = Validate(collection_name, obj, allowPartial = allowPartial)
            if not retCheck['valid']:
                ret['valid'] = retCheck['valid']
                ret['message'] = retCheck['message']
                return ret

    # Add timestamp
    for index, obj1 in enumerate(objects):
        objects[index]['createdAt'] = date_time.now_string()
        objects[index]['updatedAt'] = date_time.now_string()

    inserted_ids = collection.insert_many(objects).inserted_ids
    for index, obj1 in enumerate(objects):
        objects[index]['_id'] = from_object_id(inserted_ids[index])
    ret['items'] = objects
    return ret

def update_one(collection_name, query, mutation, upsert = False, db1 = None, validate: int = 1, allowPartial: int = 1):
    ret = { 'valid': 1, 'message': '', 'acknowledged': 0, 'matched_count': 0, 'modified_count': 0, 'upserted_id': '', }
    db = db_default(db1)
    collection = get_collection(collection_name, db)

    if validate and '$set' in mutation:
        retCheck = Validate(collection_name, mutation['$set'], allowPartial = allowPartial)
        if not retCheck['valid']:
            ret['valid'] = retCheck['valid']
            ret['message'] = retCheck['message']
            return ret

    # Add timestamp
    now_string = date_time.now_string()
    if '$set' in mutation:
        mutation['$set']['updatedAt'] = now_string
    if '$setOnInsert' not in mutation:
        mutation['$setOnInsert'] = {}
    mutation['$setOnInsert']['createdAt'] = date_time.now_string()

    # Unclear on result - modified_count can be 0 if matched and no changes?
    # So need to just check acknowledged for success? Or a combination of matched count
    # OR modified count or upserted id?
    result = collection.update_one(query, mutation, upsert=upsert)
    ret['acknowledged'] = result.acknowledged,
    ret['matched_count'] = result.matched_count,
    ret['modified_count'] = result.modified_count,
    ret['upserted_id'] = from_object_id(result.upserted_id)
    return ret
    # TODO - find and return full updated object?

def update_many(collection_name, query, mutation, db1 = None, validate: int = 1, allowPartial: int = 1):
    ret = { 'valid': 1, 'message': '', 'modified_count': 0, }
    db = db_default(db1)
    collection = get_collection(collection_name, db)

    # TODO - Add timestamp
    # for index, obj1 in enumerate(objects):
    #     objects[index]['updatedAt'] = date_time.now_string()

    if validate and '$set' in mutation:
        retCheck = Validate(collection_name, mutation['$set'], allowPartial = allowPartial)
        if not retCheck['valid']:
            ret['valid'] = retCheck['valid']
            ret['message'] = retCheck['message']
            return ret

    result = collection.update_many(query, mutation)
    ret['modified_count'] = result.modified_count
    return ret
    # TODO - find and return full updated objects?

def find_one(collection_name, query, db1 = None, fields=None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)
    # Need to convert _id to and from object id to work properly.
    if '_id' in query and query['_id'] and isinstance(query['_id'], str):
        query['_id'] = to_object_id(query['_id'])

    if fields is not None:
        result = collection.find_one(query, fields)
    else:
        result = collection.find_one(query)
    if result is not None and '_id' in result:
        result['_id'] = from_object_id(result['_id'])

    return {
        'item': result
    }

def find(collection_name, query, db1 = None, fields=None, limit=250, skip = 0, sort_obj = None):
    if limit is None:
        limit = 250
    db = db_default(db1)
    collection = get_collection(collection_name, db)
    sort = sort_to_list(sort_obj)
    if fields is not None:
        results = collection.find(query, fields)
    else:
        results = collection.find(query)
    if sort is not None:
        results = results.sort(sort)
    if limit is not None:
        results = results.limit(limit)
    if skip is not None:
        results = results.skip(skip)
    # return list(map(mapObjectIdToString, collection.find(query, limit=limit, skip=skip, sort=sort)))
    return {
        'items': list(map(map_object_id_to_string, results))
    }

def findDistinct(collectionName: str, distinctField: str, query: dict, db1 = None):
    db = db_default(db1)
    collection = get_collection(collectionName, db)
    values = collection.distinct(distinctField, query)
    return {
        'values': values,
    }

def FindRandom(collectionName: str, count: int = 1, db1 = None):
    db = db_default(db1)
    collection = get_collection(collectionName, db)
    results = collection.aggregate([
        { "$sample": { "size": count } }
    ])
    return {
        'items': list(map(map_object_id_to_string, results))
    }

def delete_one(collection_name, query, db1 = None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)
    deleted_count = collection.delete_one(query).deleted_count
    return {
        'deleted_count': deleted_count
    }

def delete_many(collection_name, query, db1 = None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)
    deleted_count = collection.delete_many(query).deleted_count
    return {
        'deleted_count': deleted_count
    }

def aggregate(collection_name, query, db1 = None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)
    results = collection.aggregate(query)
    return {
        'items': list(map(map_object_id_to_string, results))
    }

def Count(collection_name, query = {}, db1 = None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)
    count = collection.estimated_document_count()
    return {
        'count': count,
    }

def CheckGetSchema():
    global _dbSchema
    if _dbSchema is None:
        file = open('db_schema.json', 'r')
        _dbSchema = json.load(file)

def Validate(collectionName: str, item: dict, allowPartial: int = 0,
    skipRequired: list = ['_id', 'createdAt', 'updatedAt'], insertDefaults = {}):
    ret = { 'valid': 1, 'message': '', 'item': item, 'removedFields': [], }

    if not HaveId(item) and len(insertDefaults) > 0:
        item = lodash.extend_object(insertDefaults, item)

    CheckGetSchema()
    if collectionName not in _dbSchema:
        # ret['valid'] = 0
        ret['message'] = 'Collection ' + collectionName + ' not found'
        return ret

    # Check required.
    if not allowPartial:
        for field in _dbSchema[collectionName]:
            if field not in item and field not in skipRequired and '@optional' not in _dbSchema[collectionName][field]:
                if isinstance(_dbSchema[collectionName][field], list):
                    if '@optional' in _dbSchema[collectionName][field][0]:
                        continue
                    else:
                        ret['valid'] = 0
                        ret['message'] = 'Field ' + field + ' is required'
                        print ('mongo_db.Validate invalid', collectionName, ret['message'])
                        return ret
                elif isinstance(_dbSchema[collectionName][field], dict):
                    pass
                    # TODO - call recursively?
                else:
                    if '@optional' in _dbSchema[collectionName][field]:
                        continue
                    else:
                        ret['valid'] = 0
                        ret['message'] = 'Field ' + field + ' is required'
                        print ('mongo_db.Validate invalid', collectionName, ret['message'])
                        return ret

    ret = ValidatePartial(_dbSchema[collectionName], item)
    if not ret['valid']:
        print ('mongo_db.Validate invalid', collectionName, ret['message'])
    return ret

def ValidatePartial(schema: dict, item: dict, parentField: str = ''):
    ret = { 'valid': 1, 'message': '', 'item': item, 'removedFields': [], }
    if isinstance(schema, list):
        if len(schema) < 1:
            pass
        else:
            for index, itemPart in enumerate(item):
                retOne = ValidatePartial(schema[0], itemPart, parentField = parentField)
                if not retOne['valid']:
                    return retOne
                item[index] = retOne['item']
    elif isinstance(schema, dict):
        for index, field in reversed(list(enumerate(item))):
            if field not in schema:
                print ('mongo_db.ValidatePartial field', field, 'item', item[field])
                del item[field]
                ret['removedFields'].append(field)
            else:
                retOne = ValidatePartial(schema[field], item[field], parentField = field)
                if not retOne['valid']:
                    return retOne
                item[field] = retOne['item']
    elif '{Float}' in schema:
        try:
            item = float(item)
        except Exception as e:
            ret['valid'] = 0
            ret['message'] = parentField + ': Invalid float: ' + str(item)
            return ret
        if '@min' in schema:
            key = '@min '
            pos = schema.find(key)
            keyLen = len(key)
            posEnd = schema.find(' ', pos + keyLen)
            if posEnd < 0:
                posEnd = len(schema)
            minVal = float(schema[pos + keyLen:posEnd])
            if item < minVal:
                ret['valid'] = 0
                ret['message'] = parentField + ': ' + str(item) + ' is below min'
        if '@max' in schema:
            key = '@max '
            pos = schema.find(key)
            keyLen = len(key)
            posEnd = schema.find(' ', pos + keyLen)
            if posEnd < 0:
                posEnd = len(schema)
            maxVal = float(schema[pos + keyLen:posEnd])
            if item < maxVal:
                ret['valid'] = 0
                ret['message'] = parentField + ': ' + str(item) + ' is above max'
    elif '{Int}' in schema:
        try:
            item = int(item)
        except Exception as e:
            ret['valid'] = 0
            ret['message'] = parentField + ': Invalid int: ' + str(item)
            return ret
    elif '{ObjectId}' in schema:
        pass
    else:
        item = str(item)

    ret['item'] = item
    return ret
