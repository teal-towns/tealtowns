# import pymongo

def create_all_indices(db):
    # The index types are unclear to me but using `TEXT` (for start) gives an error.
    db['user'].create_index([('email', 1), ('username', 1)], unique=True)
    db['user'].create_index([('location', '2dsphere')], unique = False)

    db['image'].create_index([('title', 1), ('url', 1), ('userIdCreator', 1)], unique=True)

    db['blog'].create_index([('title', 1), ('tags', 1)], unique=True)

    # db['sharedItem'].drop_indexes()
    # db['sharedItem'].drop()
    db['sharedItem'].create_index([('title', 1), ('currentOwnerUserId', 1), ('tags', 1), \
        ('currentPrice', 1), ('minOwners', 1), ('maxOwners', 1), \
        ('status', 1), ('pledgedOwners', 1), ('fundingRequired', 1)], unique=False, \
        name = 'sharedItemIndex')
    db['sharedItem'].create_index([('location', '2dsphere')])
    # print ('sharedItem index', db['sharedItem'].index_information())

    # db['sharedItemOwner'].drop()
    db['sharedItemOwner'].create_index([('sharedItemId', 1), ('userId', 1)], unique=True)
