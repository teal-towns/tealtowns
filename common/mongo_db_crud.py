import copy

import lodash
import mongo_db
from common import math_polygon as _math_polygon

def ValidateRequired(obj, keys):
    ret = {"valid": 1, "message": ""}
    for key in keys:
        if key not in obj or len(obj[key]) == 0:
            ret["valid"] = 0
            ret["message"] = key + " is required."
            return ret
    return ret

def Get(collection: str, stringKeyVals = {}, db1 = None):
    ret = {"valid": 1, "message": ""}
    ret[collection] = {}
    query = {}
    atLeastOne = 0
    for key in stringKeyVals:
        if not isinstance(stringKeyVals[key], str) or len(stringKeyVals[key]) > 0:
            query[key] = stringKeyVals[key]
            atLeastOne = 1
    if not atLeastOne:
        ret['valid'] = 0
        ret['message'] = 'At least one key value pair is required.'
        return ret
    item = mongo_db.find_one(collection, query, db1 = db1)["item"]
    if item is not None:
        ret[collection] = item
    return ret

def GetByUName(collection: str, uName: str, db1 = None, fields = None):
    return GetById(collection, '', db1 = db1, fields = fields, uName = uName)

def GetById(collection: str, id1: str, db1 = None, fields = None, uName: str = ''):
    ret = {"valid": 1, "message": ""}
    ret[collection] = {}
    try:
        query = {}
        if len(uName) > 0:
            query = { "uName": uName }
        else:
            query = {"_id": mongo_db.to_object_id(id1)}
        item = mongo_db.find_one(collection, query, db1 = db1, fields = fields)["item"]
        if item is not None:
            ret[collection] = item
    except Exception:
        ret["valid"] = 0
        ret["message"] = "Invalid id (or uName). id: " + id1 + " uName: " + uName 
    return ret

def GetByIds(collection: str, ids: list, db1 = None, fields = None):
    ret = {"valid": 1, "message": ""}
    ret[collection] = []
    objectIds = []
    for id1 in ids:
        objectIds.append(mongo_db.to_object_id(id1))
    try:
        query = {"_id": {"$in": objectIds}}
        ret[collection] = mongo_db.find(collection, query, db1 = db1, fields = fields)["items"]
    except Exception:
        ret["valid"] = 0
        ret["message"] = "One or more invalid ids."
    return ret

def CleanId(obj: dict):
    return mongo_db.CleanId(obj)

def Save(collection: str, obj, db1 = None):
    ret = {"valid": 1, "message": "", "insert": 0}
    ret[collection] = obj

    if '_id' in obj and (not obj['_id'] or len(obj['_id']) == 0):
        del obj['_id']
    if 'createdAt' in obj:
        del obj['createdAt']
    if 'uName' in obj:
        retValid = ValidateUName(collection, obj, db1 = db1)
        if retValid["valid"] < 1:
            return retValid

    if "_id" not in obj:
        ret["insert"] = 1
        result = mongo_db.insert_one(collection, obj, db1 = db1)
        if result["valid"] == 1:
            ret[collection]["_id"] = mongo_db.from_object_id(result["item"]["_id"])
        else:
            ret["valid"] = 0
            ret["message"] = result["message"]
    else:
        ret["insert"] = 0
        query = {"_id": mongo_db.to_object_id(obj["_id"])}
        mutation = {"$set": lodash.omit(obj, ["_id", "created_at", "updated_at"])}
        result = mongo_db.update_one(collection, query, mutation, db1 = db1)
        if result["valid"] < 1:
            ret["valid"] = 0
            ret["message"] = result["message"]
    return ret

def ValidateUName(collection: str, obj: dict, db1 = None):
    ret = {"valid": 1, "message": "", }
    query = { "uName": obj["uName"] }
    if "_id" in obj:
        query["_id"] = {"$ne": mongo_db.to_object_id(obj["_id"])}
    item = mongo_db.find_one(collection, query, db1 = db1, fields = { "uName": 1 })["item"]
    if item is not None:
        ret['valid'] = 0
        ret['message'] = "uName already exists."
    return ret

def RemoveById(collection: str, id1: str, db1 = None):
    ret = {"valid": 1, "message": ""}
    query = {"_id": mongo_db.to_object_id(id1)}
    mongo_db.delete_one(collection, query, db1 = db1)
    return ret

# e.g. search('twin_model', { 'name': 'mod' }, { 'disease_names': ['alzheimer'] }, sortKeys = 'name,-created_at')
def Search(collection, stringKeyVals={}, listKeyVals={}, sortKeys="", limit=250,
    skip=0, notInListKeyVals={}, minKeyVals = {}, maxKeyVals = {}, locationKeyVals = {}, query = {},
    fields = None, db1 = None, withLocationDistance: int = 0, locationDistanceSuffix: str = '_DistanceKm',
    locationDistancePrecision = 2):
    ret = {"valid": 1, "message": ""}
    objKey = collection + "s"
    ret[objKey] = []

    query1 = FormSearchQuery(stringKeyVals, listKeyVals, notInListKeyVals, minKeyVals, maxKeyVals,
        locationKeyVals = locationKeyVals, query = query)

    sort = None
    if len(sortKeys) > 0:
        sort = {}
        for sortKey in sortKeys.split(","):
            sortVal = 1
            if sortKey[0] == "-":
                sortVal = -1
                sortKey = sortKey[(slice(1, len(sortKey)))]
            sort[sortKey] = sortVal

    ret[objKey] = mongo_db.find(collection, query1, limit=limit, skip=skip, sort_obj=sort, fields = fields, db1 = db1)["items"]
    if (withLocationDistance > 0):
        for index, item in enumerate(ret[objKey]):
            for key in locationKeyVals:
                locationKey = key + locationDistanceSuffix
                lngLat = locationKeyVals[key]['lngLat']
                ret[objKey][index][locationKey] = round(_math_polygon.Haversine(item[key]['coordinates'],
                    lngLat, units = 'kilometers'), locationDistancePrecision)
    return ret

def FormSearchQuery(stringKeyVals={}, listKeyVals={}, notInListKeyVals={}, minKeyVals = {},
    maxKeyVals = {}, locationKeyVals = {}, query = {}):
    queryCopy = copy.deepcopy(query)
    for key in stringKeyVals:
        if len(stringKeyVals[key]) > 0:
            queryCopy[key] = {"$regex": stringKeyVals[key], "$options": "i"}
    for key in listKeyVals:
        if len(listKeyVals[key]) > 0:
            if key == "_id":
                for index, val in enumerate(listKeyVals[key]):
                    listKeyVals[key][index] = mongo_db.to_object_id(val)
            queryCopy[key] = {"$in": listKeyVals[key]}
    for key in notInListKeyVals:
        if len(notInListKeyVals[key]) > 0:
            queryCopy[key] = {"$nin": notInListKeyVals[key]}
    for key in minKeyVals:
        # if len(minKeyVals[key]) > 0:
        queryCopy[key] = {"$gte": minKeyVals[key]}
    for key in maxKeyVals:
        # if len(maxKeyVals[key]) > 0:
        queryCopy[key] = {"$lte": maxKeyVals[key]}
    for key in locationKeyVals:
        if 'lngLat' in locationKeyVals[key] and 'maxMeters' in locationKeyVals[key]:
            queryCopy[key] = {
                '$nearSphere': {
                    '$geometry': {
                        'type': 'Point',
                        'coordinates': locationKeyVals[key]['lngLat'],
                    },
                    '$maxDistance': locationKeyVals[key]['maxMeters'],
                }
            }
    return queryCopy
