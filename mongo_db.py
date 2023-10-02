import pymongo
from bson.objectid import ObjectId
import ssl

import lodash
import mongo_db_indices
import date_time

_db = None

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
def insert_one(collection_name, obj1, db1 = None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)

    # Add timestamp
    obj1['createdAt'] = date_time.now_string()
    # obj = lodash.extend_object({
    #     'createdAt': date_time.now_string()
    # }, obj1);

    inserted_id = from_object_id(collection.insert_one(obj1).inserted_id)
    return {
        'item': lodash.extend_object(obj1, {
            '_id': inserted_id
        })
    }

def insert_many(collection_name, objects, db1 = None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)

    # Add timestamp
    for index, obj1 in enumerate(objects):
        objects[index]['createdAt'] = date_time.now_string()

    inserted_ids = collection.insert_many(objects).inserted_ids
    for index, obj1 in enumerate(objects):
        objects[index]['_id'] = from_object_id(inserted_ids[index])
    return {
        'items': objects
    }

def update_one(collection_name, query, mutation, upsert = False, db1 = None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)

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
    return {
        'acknowledged': result.acknowledged,
        'matched_count': result.matched_count,
        'modified_count': result.modified_count,
        'upserted_id': from_object_id(result.upserted_id)
    }
    # TODO - find and return full updated object?

def update_many(collection_name, query, mutation, db1 = None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)

    # TODO - Add timestamp
    # for index, obj1 in enumerate(objects):
    #     objects[index]['updatedAt'] = date_time.now_string()

    result = collection.update_many(query, mutation)
    return {
        'modified_count': result.modified_count
    }
    # TODO - find and return full updated objects?

def find_one(collection_name, query, db1 = None, fields=None):
    db = db_default(db1)
    collection = get_collection(collection_name, db)
    # Need to convert _id to and from object id to work properly.
    if '_id' in query and query['_id']:
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
