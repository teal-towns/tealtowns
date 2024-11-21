import datetime

import date_time
import lodash
import mongo_db
from user_payment import user_payment as _user_payment
from event import user_event as _user_event

def RunAll():
    # UserEventSelfHost()
    # EventAttendeeCache()
    # ToCreditUSD()
    # AddHostInterests()
    # UserNeighborhoodWeeklyUpdateActionsComplete()
    # AddLocationAddress()
    # WeeklyEventTags()
    # CleanUpEmptyUsernames()
    # AddUsernames()
    # AddWeeklyEventUName()
    # UserInsightAmbassadorNetworkStepsAt()
    # UserInsightAmbassadorSignUpStepsAt()
    # UserNeighborhoodVision()
    # UserNeighborhoodToUName()
    # UserNeighborhoodRoles()
    # EventFeedbackImageUrls()
    # FeedbackStarsAttended()
    # EventViewsAt()
    # AddTimezoneToNeighborhood()
    # PayQuantityAndStripeIds()
    # AddPositiveVotes()
    # AddNeighborhoodUName()
    # WeeklyEventArchived()
    # TimesToUTC()
    # AddEventEnd()
    # AddUserEventEnd()
    # SharedItemMaxMeters()
    # SharedItemUName()
    # ImportCertificationLevels()
    pass

def UserEventSelfHost():
    collections = ['userEvent']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'selfHostCount': { '$exists': 0 } }
            fields = { '_id': 1, }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('UserEventSelfHost', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'selfHostCount': 0,
                    }
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def EventAttendeeCache():
    collections = ['event']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'userEventsAttendeeCache': { '$exists': 0 } }
            fields = { '_id': 1, }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('EventAttendeeCache', collection, len(items))
            for item in items:
                _user_event.GetStats(item['_id'], updateEventCache = 1)

                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def ToCreditUSD():
    collections = ['userMoney']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'creditBalanceUSD': { '$exists': 0 } }
            fields = { '_id': 1, }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('ToCreditUSD', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'creditBalanceUSD': 0,
                    }
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break
    
    collections = ['userPaymentSubscription']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'creditUSD': { '$exists': 0 } }
            fields = { '_id': 1, 'userId': 1, 'forType': 1, 'forId': 1, 'quantity': 1, 'credits': 1, 'amountUSD': 1 }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('ToCreditUSD', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                creditUSD = 0
                if 'credits' in item and item['credits'] != 0:
                    fields = { 'priceUSD': 1, }
                    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(item['forId'])}, fields = fields)['item']
                    creditUSD = item['credits'] * weeklyEvent['priceUSD']
                    if creditUSD > item['amountUSD']:
                        creditUSD = item['amountUSD']
                    print (collection, item['credits'], 'AddCreditPayment', item['userId'], creditUSD, 'weeklyEvent', item['forId'])
                    retPay = _user_payment.AddCreditPayment(item['userId'], creditUSD, 'weeklyEvent', item['forId'])
                mutation = {
                    '$unset': {
                        'credits': 1,
                    },
                    '$set': {
                        'creditUSD': creditUSD,
                    }
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

    collections = ['userEvent']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'creditsEarned': { '$exists': 1 } }
            fields = { '_id': 1, 'userId': 1, 'eventId': 1, 'creditsPriceUSD': 1, 'creditsEarned': 1,
                'creditsRedeemed': 1, }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('ToCreditUSD', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                credits = item['creditsEarned'] - item['creditsRedeemed']
                # We previously added canceled subscription credits to events, so this will double count them..
                # For now just limit to credits of 1 or less (this is not perfect and will over-award some money
                # but only affects ~1 live user so it is okay).
                if credits != 0 and credits <= 1:
                    creditUSD = float(credits * item['creditsPriceUSD'])
                    print (collection, credits, 'AddCreditPayment', item['userId'], creditUSD, 'event', item['eventId'])
                    _user_payment.AddCreditPayment(item['userId'], creditUSD, 'event', item['eventId'])
                mutation = {
                    '$unset': {
                        'creditsEarned': 1,
                        'creditsRedeemed': 1,
                        'creditsPriceUSD': 1,
                    },
                    '$set': {
                        'priceUSD': item['creditsPriceUSD'],
                    }
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def AddHostInterests():
    collections = ['userInterest']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'hostInterests': { '$exists': 0 } }
            fields = { '_id': 1, }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('AddHostInterests', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'hostInterests': [],
                        'hostInterestsPending': [],
                    }
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def UserNeighborhoodWeeklyUpdateActionsComplete():
    collections = ['userNeighborhoodWeeklyUpdate']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'actionsComplete': { '$exists': 0 } }
            fields = { '_id': 1, }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('UserNeighborhoodWeeklyUpdateActionsComplete', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'actionsComplete': [],
                    }
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def AddLocationAddress():
    collections = ['weeklyEvent', 'neighborhood']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'locationAddress': { '$exists': 0 } }
            fields = { '_id': 1, }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('AddLocationAddress', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'locationAddress': {},
                    }
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def WeeklyEventTags():
    collections = ['weeklyEvent']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'tags': { '$exists': 0} }
            fields = None
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('WeeklyEventTags', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'tags': [],
                    },
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def CleanUpEmptyUsernames():
    collections = ['userNeighborhood', 'userNeighborhoodWeeklyUpdate']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'username': '' }
            fields = None
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('CleanUpEmptyUsernames', collection, len(items))
            for item in items:
                # print ('deleting item', item)
                mongo_db.delete_one(collection, { '_id': mongo_db.to_object_id(item['_id']) })
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def AddUsernames():
    collections = ['userNeighborhood', 'userNeighborhoodWeeklyUpdate', 'userInsight', 'userFeedback', 'userEvent']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'username': { '$exists': 0 } }
            fields = { '_id': 1, 'userId': 1 }
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('AddUsernames', collection, len(items))
            for item in items:
                fields = { 'username': 1 }
                user = mongo_db.find_one('user', {'_id': item['userId']}, fields = fields)['item']
                if user is not None:
                    query = {
                        '_id': mongo_db.to_object_id(item['_id'])
                    }
                    mutation = {
                        '$set': {
                            'username': user['username'],
                        },
                    }

                    # print (query, mutation)
                    mongo_db.update_one(collection, query, mutation)
                    updatedCounter += 1
                else:
                    print('User not found: ' + item['userId'])

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def AddWeeklyEventUName():
    collections = ['event', 'userWeeklyEvent', 'userEvent']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'weeklyEventUName': { '$exists': 0 } }
            fields = {}
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('AddWeeklyEventUName', collection, len(items))
            for item in items:
                weeklyEvent = None
                if collection == 'event' and len(item['weeklyEventId']) > 0:
                    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(item['weeklyEventId'])})['item']
                elif collection == 'userWeeklyEvent':
                    weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(item['weeklyEventId'])})['item']
                elif collection == 'userEvent':
                    event = mongo_db.find_one('event', {'_id': mongo_db.to_object_id(item['eventId'])})['item']
                    if event is not None and len(event['weeklyEventId']) > 0:
                        weeklyEvent = mongo_db.find_one('weeklyEvent', {'_id': mongo_db.to_object_id(event['weeklyEventId'])})['item']
                if weeklyEvent is not None:
                    query = {
                        '_id': mongo_db.to_object_id(item['_id'])
                    }
                    mutation = {
                        '$set': {
                            'weeklyEventUName': weeklyEvent['uName'],
                        }
                    }

                    # print (collection, query, mutation)
                    mongo_db.update_one(collection, query, mutation)
                    updatedCounter += 1
                else:
                    print ('WeeklyEvent not found', collection, item['_id'])

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def UserInsightAmbassadorNetworkStepsAt():
    collection = 'userInsight'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'ambassadorNetworkStepsAt': { '$exists': 0 } }
        fields = { '_id': 1, }
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('UserInsightAmbassadorNetworkStepsAt', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'ambassadorNetworkStepsAt': {},
                },
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def UserInsightAmbassadorSignUpStepsAt():
    collection = 'userInsight'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'ambassadorSignUpStepsAt': { '$exists': 0 } }
        fields = { '_id': 1, }
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('UserInsightAmbassadorSignUpStepsAt', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'ambassadorSignUpStepsAt': {},
                },
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def UserNeighborhoodVision():
    collection = 'userNeighborhood'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'vision': { '$exists': 0 } }
        fields = { '_id': 1, }
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('userNeighborhoodVision', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'vision': '',
                    'motivations': [],
                },
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def UserNeighborhoodToUName():
    collection = 'userNeighborhood'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'neighborhoodUName': { '$exists': 0 } }
        fields = { '_id': 1, 'neighborhoodId': 1, }
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('userNeighborhoodToUName', collection, len(items))
        for item in items:
            fields = { 'uName': 1, }
            print ('item', item)
            neighborhood = mongo_db.find_one('neighborhood', { '_id': mongo_db.to_object_id(item['neighborhoodId']) }, fields = fields)['item']
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'neighborhoodUName': neighborhood['uName'],
                },
                '$unset': { 'neighborhoodId': 1 },
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def UserNeighborhoodRoles():
    collection = 'userNeighborhood'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'roles': { '$exists': 0 } }
        fields = { '_id': 1, }
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('userNeighborhoodRoles', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'roles': ['creator', 'ambassador'],
                }
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def EventFeedbackImageUrls():
    collection = 'eventFeedback'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'imageUrls': { '$exists': 0 } }
        fields = { '_id': 1, }
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('EventFeedbackImageUrls', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'imageUrls': [],
                }
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def FeedbackStarsAttended():
    collection = 'userFeedback'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'stars': { '$exists': 0 } }
        fields = { '_id': 1, }
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('FeedbackStarsAttended', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'stars': 5,
                    'attended': 'yes',
                }
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def EventViewsAt():
    collection = 'eventInsight'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'viewsAt': { '$exists': 1 } }
        fields = { '_id': 1, 'viewsAt': 1,}
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('EventViewsAt', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$unset': {
                    'viewsAt': '',
                },
                '$set': {
                    'uniqueViewsAt': {},
                }
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def AddTimezoneToNeighborhood():
    collection = 'neighborhood'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'timezone': { '$exists': 0 } }
        fields = { '_id': 1, 'location': 1,}
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('AddTimezoneToNeighborhood', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'timezone': date_time.GetTimezoneFromLngLat(item['location']['coordinates']),
                }
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def PayQuantityAndStripeIds():
    collections = ['userPayment', 'userPaymentSubscription']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'quantity': { '$exists': 0 } }
            fields = {}
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('PayQuantityAndStripeIds', collection, len(items))
            for item in items:
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'quantity': 1,
                    }
                }
                if collection == 'userPaymentSubscription':
                    mutation['$unset'] = {'stripeId': ''}
                    mutation['$set']['stripeIds'] = { 'checkoutSession': item['stripeId'] }
                    mutation['$set']['credits'] = 0

                # print (collection, query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def AddPositiveVotes():
    collection = 'eventFeedback'
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'positiveVotes': { '$exists': 0 } }
        fields = { '_id': 1,}
        items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('AddPositiveVotes', collection, len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'positiveVotes': [],
                }
            }

            # print (query, mutation)
            mongo_db.update_one(collection, query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

def AddNeighborhoodUName():
    collections = ['weeklyEvent', 'event', 'sharedItem']
    for collection in collections:
        limit = 250
        skip = 0
        updatedCounter = 0
        while True:
            query = {'neighborhoodUName': { '$exists': 0 } }
            fields = { '_id': 1, 'uName': 1,}
            items = mongo_db.find(collection, query, limit=limit, skip=skip, fields = fields)['items']
            skip += len(items)

            print ('AddNeighborhoodUName', collection, len(items))
            for item in items:
                neighborhoodUName = 'southsidefw' if 'uName' in item and item['uName'] == 'fma4t' else 'concordpc'
                query = {
                    '_id': mongo_db.to_object_id(item['_id'])
                }
                mutation = {
                    '$set': {
                        'neighborhoodUName': neighborhoodUName,
                    }
                }

                # print (query, mutation)
                mongo_db.update_one(collection, query, mutation)
                updatedCounter += 1

            if len(items) < limit:
                print('Updated ' + str(updatedCounter) + ' items')
                break

def WeeklyEventArchived():
    limit = 250
    skip = 0
    updatedCounter = 0
    while True:
        query = {'archived': { '$exists': 0 }}
        fields = { 'archived': 1,}
        items = mongo_db.find('weeklyEvent', query, limit=limit, skip=skip, fields = fields)['items']
        skip += len(items)

        print ('WeeklyEventArchived weeklyEvent', len(items))
        for item in items:
            query = {
                '_id': mongo_db.to_object_id(item['_id'])
            }
            mutation = {
                '$set': {
                    'archived': 0,
                }
            }

            # print (query, mutation)
            mongo_db.update_one('weeklyEvent', query, mutation)
            updatedCounter += 1

        if len(items) < limit:
            print('Updated ' + str(updatedCounter) + ' items')
            break

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
        query = { '$or': [ { 'eventEnd': { '$exists': 0 } }, { 'eventEnd': '' } ] }
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
