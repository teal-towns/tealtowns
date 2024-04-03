# import pymongo

def create_all_indices(db):
    db['user'].create_index([('email', 1), ('username', 1)], unique=True)
    db['user'].create_index([('location', '2dsphere')], unique = False)

    db['image'].create_index([('title', 1), ('url', 1), ('userIdCreator', 1)], unique=True)

    db['blog'].create_index([('title', 1), ('tags', 1)], unique=True)

    db['weeklyEvent'].drop_indexes()
    db['weeklyEvent'].drop()
    db['weeklyEvent'].create_index([('uName', 1)], unique=True)
    db['weeklyEvent'].create_index([('title', 1), ('type', 1), ('priceUSD', 1)], unique=False)
    db['weeklyEvent'].create_index([('location', '2dsphere')])

    db['event'].create_index([('weeklyEventId', 1), ('start', 1)], unique=False)

    db['userWeeklyEvent'].create_index([('userId', 1), ('weeklyEventId', 1)], unique=True)
    db['userWeeklyEvent'].create_index([('status', 1)], unique=False)

    db['userEvent'].create_index([('userId', 1), ('eventId', 1)], unique=True)
    db['userEvent'].create_index([('creditsPriceUSD', 1), ('hostStatus', 1), ('attendeeStatus', 1)], unique=False)

    db['sharedItem'].create_index([('title', 1), ('currentOwnerUserId', 1), ('currentPurchaserUserId', 1), \
        ('tags', 1), \
        ('currentPrice', 1), ('minOwners', 1), ('maxOwners', 1), ('maxMeters', 1), ('bought', 1), \
        ('status', 1), ('pledgedOwners', 1), ('fundingRequired', 1)], unique=False, \
        name = 'sharedItemIndex')
    db['sharedItem'].create_index([('location', '2dsphere')])
    # print ('sharedItem index', db['sharedItem'].index_information())

    db['sharedItemOwner'].create_index([('sharedItemId', 1), ('userId', 1), ('generation', 1)], unique=True)

    db['userMoney'].create_index([('userId', 1)], unique=True)

    db['userPayment'].create_index([('userId', 1), ('forType', 1), ('forId', 1), ('status', 1)], unique=False)

    db['userPaymentSubscription'].create_index([('userId', 1), ('forType', 1), ('forId', 1), \
        ('status', 1)], unique=False)
    
    db['userStripeAccount'].create_index([('userId', 1)], unique=True)
