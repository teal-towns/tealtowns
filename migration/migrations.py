import datetime

import date_time
import lodash
import mongo_db

def RunAll():
    TimesToUTC()
    # AddEventEnd()
    # AddUserEventEnd()
    # SharedItemMaxMeters()
    # SharedItemUName()
    # ImportCertificationLevels()
    pass

def TimesToUTC():
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {}
        fields = { 'start': 1, 'end': 1,}
        items = mongo_db.find('event', query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('TimesToUTC event', len(items))
        for item in items:
            startUTC = date_time.string(date_time.toUTC(date_time.from_string(item['start'])))
            endUTC = date_time.string(date_time.toUTC(date_time.from_string(item['end'])))
            if startUTC != item['start'] or endUTC != item['end']:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'start': startUTC,
                        'end': endUTC,
                    }
                }

                # print (query, mutation, item['start'], item['end'])
                mongo_db.update_one('event', query, mutation)
                updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break
    
    skip = 0
    updatedCounter = 0
    while True:
        query = {}
        fields = { 'eventEnd': 1,}
        items = mongo_db.find('userEvent', query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('TimesToUTC userEvent', len(items))
        for item in items:
            endUTC = date_time.string(date_time.toUTC(date_time.from_string(item['eventEnd'])))
            if endUTC != item['eventEnd']:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'eventEnd': endUTC,
                    }
                }

                # print (query, mutation, item['start'], item['end'])
                mongo_db.update_one('userEvent', query, mutation)
                updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def AddEventEnd():
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = { 'end': { '$exists': 0 } }
        items = mongo_db.find('event', query, limit=limit, skip=skip)['items']
        skip += len(items)

        print ('AddEventEnd', len(items))
        for item in items:
            if len(item['weeklyEventId']) > 0:
                weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(item['weeklyEventId'])})['item']
                if weeklyEvent is not None:
                    hour = int(weeklyEvent['startTime'][0:2])
                    minute = int(weeklyEvent['startTime'][3:5])
                    hourEnd = int(weeklyEvent['endTime'][0:2])
                    minuteEnd = int(weeklyEvent['endTime'][3:5])
                    durationHours = hourEnd - hour
                    if durationHours < 0:
                        durationHours += 24
                    durationMinutes = minuteEnd - minute
                    duration = durationHours * 60 + durationMinutes
                    end = date_time.from_string(item['start']) + datetime.timedelta(minutes = duration)
                    end = date_time.string(end)

                    query = {
                        '_id': mongo_db.to_object_id(item['_id'])
                    }
                    mutation = {
                        '$set': {
                            'end': end,
                        }
                    }

                    # print (query, mutation, item['start'])
                    mongo_db.update_one('event', query, mutation)
                    updatedCounter += 1
                else:
                    print ('No weeklyEvent', item)
                    query = {
                        '_id': mongo_db.to_object_id(item['_id'])
                    }
                    mongo_db.delete_one('event', query)
            else:
                print ('No weeklyEventId', item)

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def AddUserEventEnd():
    limit = 250
    skip = 0
    updatedCounter = 0

    while True:
        query = { 'eventEnd': { '$exists': 0 } }
        items = mongo_db.find('userEvent', query, limit=limit, skip=skip)['items']
        skip += len(items)

        print ('AddUserEventEnd', len(items))
        for item in items:
            event = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(item['eventId'])})['item']
            if event is not None and 'end' in event:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'eventEnd': event['end'],
                    }
                }
                # print (query, mutation)
                mongo_db.update_one('userEvent', query, mutation)
                updatedCounter += 1
            else:
                print ('No event, or no end', item['eventId'], 'event', event)
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mongo_db.delete_one('userEvent', query)

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

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

# def ImportCertificationLevels():
#     from neighborhood import certification_level_import as _certification_level_import
#     items = mongo_db.find('certificationLevel', {})['items']
#     if len(items) == 0:
#         _certification_level_import.ImportToDB()
#         print ('Imported certificationLevels')
