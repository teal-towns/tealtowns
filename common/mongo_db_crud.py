import lodash
import mongo_db

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

def GetById(collection: str, id1: str, db1 = None):
    ret = {"valid": 1, "message": ""}
    ret[collection] = {}
    try:
        query = {"_id": mongo_db.to_object_id(id1)}
        item = mongo_db.find_one(collection, query, db1 = db1)["item"]
        if item is not None:
            ret[collection] = item
    except Exception:
        ret["valid"] = 0
        ret["message"] = "Invalid id."
    return ret

def Save(collection: str, obj, db1 = None):
    ret = {"valid": 1, "message": "", "insert": 0}
    ret[collection] = obj

    if '_id' in obj and (not obj['_id'] or len(obj['_id']) == 0):
        del obj['_id']
    if "_id" not in obj:
        ret["insert"] = 1
        result = mongo_db.insert_one(collection, obj, db1 = db1)
        ret[collection]["_id"] = mongo_db.from_object_id(result["item"]["_id"])
    else:
        ret["insert"] = 0
        query = {"_id": mongo_db.to_object_id(obj["_id"])}
        mutation = {"$set": lodash.omit(obj, ["_id", "created_at", "updated_at"])}
        result = mongo_db.update_one(collection, query, mutation, db1 = db1)
    return ret

def RemoveById(collection: str, id1: str, db1 = None):
    ret = {"valid": 1, "message": ""}
    query = {"_id": mongo_db.to_object_id(id1)}
    mongo_db.delete_one(collection, query, db1 = db1)
    return ret

# e.g. search('twin_model', { 'name': 'mod' }, { 'disease_names': ['alzheimer'] }, sortKeys = 'name,-created_at')
def Search(collection, stringKeyVals={}, listKeyVals={}, sortKeys="", limit=250,
    skip=0, notInListKeyVals={}, minKeyVals = {}, maxKeyVals = {}, query = {}, fields = None, db1 = None):
    ret = {"valid": 1, "message": ""}
    objKey = collection + "s"
    ret[objKey] = []

    query = FormSearchQuery(stringKeyVals, listKeyVals, notInListKeyVals, minKeyVals, maxKeyVals, query = query)

    sort = None
    if len(sortKeys) > 0:
        sort = {}
        for sortKey in sortKeys.split(","):
            sortVal = 1
            if sortKey[0] == "-":
                sortVal = -1
                sortKey = sortKey[(slice(1, len(sortKey)))]
            sort[sortKey] = sortVal

    ret[objKey] = mongo_db.find(collection, query, limit=limit, skip=skip, sort_obj=sort, fields = fields, db1 = db1)["items"]
    return ret

def FormSearchQuery(stringKeyVals={}, listKeyVals={}, notInListKeyVals={}, minKeyVals = {},
    maxKeyVals = {}, query = {}):
    for key in stringKeyVals:
        if len(stringKeyVals[key]) > 0:
            query[key] = {"$regex": stringKeyVals[key], "$options": "i"}
    for key in listKeyVals:
        if len(listKeyVals[key]) > 0:
            if key == "_id":
                for index, val in enumerate(listKeyVals[key]):
                    listKeyVals[key][index] = mongo_db.to_object_id(val)
            query[key] = {"$in": listKeyVals[key]}
    for key in notInListKeyVals:
        if len(notInListKeyVals[key]) > 0:
            query[key] = {"$nin": notInListKeyVals[key]}
    for key in minKeyVals:
        # if len(minKeyVals[key]) > 0:
        query[key] = {"$gte": minKeyVals[key]}
    for key in maxKeyVals:
        # if len(maxKeyVals[key]) > 0:
        query[key] = {"$lte": maxKeyVals[key]}
    return query
