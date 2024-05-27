import mongo_db
from neighborhood import neighborhood_stats as _neighborhood_stats

def AddNeighborhood(uName: str, neighborhoodUName: str):
    ret = { "valid": 1, "message": "", "neighborhoodGroup": {}, }
    query = { "uName": uName }
    mutation = { "$addToSet": { "neighborhoodUNames": neighborhoodUName } }
    mongo_db.update_one('neighborhoodGroup', query, mutation)
    ret['neighborhoodGroup'] = mongo_db.find_one('neighborhoodGroup', query)['item']
    return ret 

def RemoveNeighborhoods(uName: str, neighborhoodUNames: list):
    ret = { "valid": 1, "message": "", "neighborhoodGroup": {}, }
    query = { "uName": uName }
    mutation = { "$pull": { "neighborhoodUNames": { "$in": neighborhoodUNames } } }
    mongo_db.update_one('neighborhoodGroup', query, mutation)
    ret['neighborhoodGroup'] = mongo_db.find_one('neighborhoodGroup', query)['item']
    return ret

async def ComputeStats(uName: str, onUpdate):
    ret = { "valid": 1, "message": "", "countTotal": 0, "countDone": 0,
        "neighborhoodInfos": [], "previousNeighborhoodInfos": [], }
    query = { "uName": uName }
    neighborhoodGroup = mongo_db.find_one('neighborhoodGroup', query)['item']
    if neighborhoodGroup is None:
        ret['valid'] = 0
        ret['message'] = 'Invalid uName: ' + uName
        await onUpdate(ret)
        return ret
    ret['countTotal'] = len(neighborhoodGroup['neighborhoodUNames'])
    await onUpdate(ret)
    for neighborhoodUName in neighborhoodGroup['neighborhoodUNames']:
        retOne = _neighborhood_stats.ComputeNeighborhoodStats(neighborhoodUName)
        ret['neighborhoodInfos'].append(retOne['neighborhoodStats'])
        ret['previousNeighborhoodInfos'].append(retOne['previousNeighborhoodStats'])
        ret['countDone'] += 1
        await onUpdate(ret)
