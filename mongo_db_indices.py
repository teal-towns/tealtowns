import pymongo

def create_all_indices(db):
    # The index types are unclear to me but using `TEXT` (for start) gives an error.
    db['user'].create_index([('email', pymongo.ASCENDING), \
        ('username', pymongo.ASCENDING)], unique=True)

    db['image'].create_index([('title', pymongo.ASCENDING), \
        ('url', pymongo.ASCENDING), ('userIdCreator', pymongo.ASCENDING)], unique=True)
    
    db['blog'].create_index([('title', pymongo.ASCENDING), \
        ('tags', pymongo.ASCENDING)], unique=True)
