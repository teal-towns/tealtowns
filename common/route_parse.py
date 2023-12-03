import time

def formatRet(data, ret, arrayJoinKeys=[], arrayJoinDelimiter=","):
    stringKeys = data['string_keys'] if 'string_keys' in data else 1
    if stringKeys:
        ret = objectToStringKeys(ret, arrayJoinKeys, arrayJoinDelimiter)
    return ret

def objectToStringKeys(obj, arrayJoinKeys=[], arrayJoinDelimiter=","):
    if isinstance(obj, list):
        for item in obj:
            item = objectToStringKeys(item, arrayJoinKeys, arrayJoinDelimiter)
    elif isinstance(obj, dict):
        for key in obj:
            if isinstance(obj[key], list):
                if key in arrayJoinKeys:
                    obj[key] = arrayJoinDelimiter.join(obj[key])
                else:
                    obj[key] = objectToStringKeys(obj[key], arrayJoinKeys, arrayJoinDelimiter)
            elif isinstance(obj[key], dict):
                obj[key] = objectToStringKeys(obj[key], arrayJoinKeys, arrayJoinDelimiter)
            else:
                obj[key] = str(obj[key])
    else:
        obj = str(obj)
    return obj

def GetTimestamp():
    return int(time.time())

def AddTimestamp(ret):
    ret['timestamp'] = GetTimestamp()
    return ret
