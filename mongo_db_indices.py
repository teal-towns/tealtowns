# import pymongo

def create_all_indices(db):
    db['user'].create_index([('email', 1), ('username', 1)], unique=True)
    db['user'].create_index([('location', '2dsphere')], unique = False)

    db['image'].create_index([('title', 1), ('url', 1), ('userIdCreator', 1)], unique=True)

    db['blog'].create_index([('title', 1), ('tags', 1)], unique=True)

    # db['sharedItem'].drop_indexes()
    # db['sharedItem'].drop()
    db['sharedItem'].create_index([('title', 1), ('currentOwnerUserId', 1), ('currentPurchaserUserId', 1), \
        ('tags', 1), \
        ('currentPrice', 1), ('minOwners', 1), ('maxOwners', 1), ('maxMeters', 1), ('bought', 1), \
        ('status', 1), ('pledgedOwners', 1), ('fundingRequired', 1)], unique=False, \
        name = 'sharedItemIndex')
    db['sharedItem'].create_index([('location', '2dsphere')])
    # print ('sharedItem index', db['sharedItem'].index_information())

    # db['sharedItemOwner'].drop()
    # db['sharedItemOwner'].drop_indexes()
    db['sharedItemOwner'].create_index([('sharedItemId', 1), ('userId', 1), ('generation', 1)], unique=True)

    db['userMoney'].create_index([('userId', 1)], unique=True)

    db['userPayment'].create_index([('userId', 1), ('forType', 1), ('forId', 1), ('status', 1)], unique=False)
