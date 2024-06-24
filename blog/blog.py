import mongo_db
import re

def Get(title = '', tags = [], userIdCreator = '', slug = '', limit = 25, skip = 0,
    sortKeys = ''):
    ret = { 'valid': 1, 'message': '', 'blogs': [] }
    query = {}
    if len(tags) > 0:
        query['tags'] = { '$in': tags }
    if len(title) > 0:
        query['title'] = { '$regex': title, '$options': 'i' };
    if len(slug) > 0:
        query['slug'] = { '$regex': slug, '$options': 'i' };
    if len(userIdCreator) > 0:
        query['userIdCreator'] = userIdCreator
    sort = None
    if len(sortKeys) > 0:
        sort = {}
        for sortKey in sortKeys.split(","):
            sortVal = 1
            if sortKey[0] == "-":
                sortVal = -1
                sortKey = sortKey[(slice(1, len(sortKey)))]
            sort[sortKey] = sortVal
    ret['blogs'] = mongo_db.find('blog', query, limit = limit, skip = skip, sort_obj = sort)['items']
    return ret

def Save(blog, userIdCreator = ''):
    ret = { 'valid': 1, 'message': '', 'blog': {} }

    if '_id' not in blog or not blog['_id']:
        blog['userIdCreator'] = userIdCreator
        blog['slug'] = GetSlug(blog['title'])
        insertDefaults = {
            'tags': [],
        }
        retCheck = mongo_db.Validate('blog', blog, insertDefaults = insertDefaults)
        if not retCheck['valid']:
            return retCheck
        blog = retCheck['item']
        result = mongo_db.insert_one('blog', blog)
        blog['_id'] = mongo_db.from_object_id(result['item']['_id'])
    else:
        query = {
            '_id': mongo_db.to_object_id(blog['_id'])
        }
        mutation = {
            '$set': {
                'title': blog['title'],
                'text': blog['text'],
                'tags': blog['tags'],
                'imageUrl': blog['imageUrl'],
                'imageCredit': blog['imageCredit'],
            }
        }
        result = mongo_db.update_one('blog', query, mutation)
    ret['blog'] = blog
    return ret

def Remove(id):
    ret = { 'valid': 1, 'message': '' }
    query = {
        '_id': mongo_db.to_object_id(id),
    }
    result = mongo_db.delete_one('blog', query)
    return ret

def GetSlug(title, maxChars = 40):
    slug = title.lower().strip()
    regex = re.compile('\s')
    slug = regex.sub('-', slug)
    regex = re.compile('[^a-zA-Z0-9-]')
    slug = regex.sub('', slug)
    if len(slug) > maxChars:
        slug = slug[slice(0, maxChars)]
    # Check database for existing slug and increment counter suffix until have
    # a unique one.
    query = {
        'slug': {
            '$regex': '^' + slug
        }
    }
    fields = {
        'slug': 1
    }
    blogs = mongo_db.find('blog', query, fields=fields)['items']
    if len(blogs) < 1:
        slugFinal = slug
    else:
        existingSlugs = list(map(lambda item: item['slug'], blogs))
        slugFinal = None
        slugCheck = slug
        countSuffix = 0
        while slugFinal is None:
            if slugCheck not in existingSlugs:
                slugFinal = slugCheck
            else:
                countSuffix += 1
                slugCheck = slug + str(countSuffix)

    return slugFinal
