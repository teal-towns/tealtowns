import copy
import random
import re

def findIndex(array1, key, value):
    return find_index(array1, key, value)

def find_index(array1, key, value):
    for index, arr_item in enumerate(array1):
        if key in arr_item and arr_item[key] == value:
            return index
    return -1

def extend_object(default, new):
    final = {}
    # Go through defaults first
    for key in default:
        if key not in new:
            final[key] = default[key]
        else:
            final[key] = new[key]
    # In case any keys in new but not in default, add them
    for key in new:
        if key not in final:
            final[key] = new[key]
    return final

def sort2D(array1, key, order = 'ascending'):
    if len(array1) < 2:
        return array1

    # def compare(a, b):
    #     aVal = a[key]
    #     bVal = b[key]
    #     if aVal == bVal:
    #         return 0
    #     if (aVal > bVal and order == 'ascending') or (aVal < bVal and order == 'descending'):
    #         return 1
    #     return -1
    def getValue(item):
        return item[key]

    if key[0] == '-':
        key = key[1:]
        order = 'descending'
    reverse = True if order == 'descending' else False
    return sorted(array1, key=getValue, reverse=reverse)

def omit(object1, keys = [], skipNull = 1):
    new_object = {}
    for key in object1:
        if key not in keys:
            if not skipNull or (str(object1[key]) != 'null' and object1[key] != None):
                new_object[key] = object1[key]
    return new_object

def pick(object1, keys = []):
    new_object = {}
    for key in object1:
        if key in keys:
            new_object[key] = object1[key]
    return new_object

def map_pick(array1, keys = []):
    def pick1(obj1):
        return pick(obj1, keys)

    return list(map(pick1, array1))

def mapOmit(array1, omitKeys = []):
    def omit1(obj1):
        return omit(obj1, omitKeys)

    return list(map(omit1, array1))

def get_key_array(items, key, skipEmpty=0, emptyValue=None):
    if skipEmpty:
        return list(map(lambda item: item[key] if key in item else emptyValue, items))
    else:
        return list(map(lambda item: item[key], items))

# def append_if_unique(array1, value):
#     if value not in array1:
#         array1.append(value)

def random_string(length = 10, charsType = 'full'):
    text = ''
    chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    if charsType == 'readable':
        chars = 'abcdefghijkmnopqrstuvwxyz023456789'
    elif charsType == 'numeric':
        chars = '0123456789'
    chars_length = len(chars)
    counter = 0
    while counter < length:
        index = random.randint(0, (chars_length - 1))
        text = text + chars[index]
        counter = counter + 1
    return text

def removeArrayIndices(array, indices):
    array1 = copy.deepcopy(array)
    for index, item in reversed(list(enumerate(array1))):
        if index in indices:
            del array1[index]
    return array1

def CreateUName(title, maxChars = 7, minChars = 6):
    # Remove all non letters, go to lowercase, then cut at max length to make a username.
    uName = title.lower()
    regex = re.compile('[^a-zA-Z]')
    uName = regex.sub('', uName)
    if len(uName) > maxChars:
        uName = uName[slice(0, maxChars)]
    if len(uName) < minChars:
        uName += random_string(minChars - len(uName), 'readable')
    return uName

def FormUNameSuffix(uNameCheck, existingUNames, maxLoops = 10):
    uNameFinal = None
    loopCount = 0
    while uNameFinal is None:
        suffix = random_string(10, 'readable')
        indexSuffix = 0
        while uNameFinal is None and indexSuffix < len(suffix):
            if uNameCheck not in existingUNames:
                uNameFinal = uNameCheck
            else:
                uNameCheck += suffix[indexSuffix]
                indexSuffix += 1
        loopCount += 1
        if loopCount > maxLoops:
            print ('lodash.FormUNameSuffix maxLoops, stopping')
            break
    return uNameFinal
