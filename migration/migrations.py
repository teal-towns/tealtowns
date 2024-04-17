import lodash
import mongo_db

def RunAll():
    # SharedItemMaxMeters()
    SharedItemUName()
    pass

def SharedItemMaxMeters():
    limit = 250
    skip = 0
    updatedCounter = 0

    while True:
        items = mongo_db.find('sharedItem', {}, limit=limit, skip=skip)['items']
        skip += len(items)

        print ('SharedItemMaxMeters', len(items))
        for item in items:
            if 'maxMeters' not in item:
                item['maxMeters'] = 1500
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'maxMeters': item['maxMeters'],
                    }
                }

                # print (query, mutation)
                mongo_db.update_one('sharedItem', query, mutation)
                updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def SharedItemUName():
    limit = 250
    skip = 0
    updatedCounter = 0

    while True:
        fields = { '_id': 1, 'title': 1, 'uName': 1, }
        items = mongo_db.find('sharedItem', {}, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('SharedItemUName', len(items))
        for item in items:
            if 'uName' not in item:
                item['uName'] = lodash.CreateUName(item['title'])
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'uName': item['uName'],
                    }
                }

                # print (query, mutation)
                mongo_db.update_one('sharedItem', query, mutation)
                updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break
