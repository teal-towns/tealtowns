import mongo_mock as _mongo_mock
import mongo_db
from shared_item import shared_item_owner as _shared_item_owner
from stubs import stubs_data as _stubs_data

def test_Save():
    _mongo_mock.InitAllCollections()

    sharedItem = _stubs_data.CreateBulk(count = 1, collectionName = 'sharedItem')[0]
    user = _stubs_data.CreateBulk(count = 1, collectionName = 'user')[0]
    # Should have a payment added.
    obj = {
        "sharedItemId": sharedItem['_id'],
        "userId": user['_id'],
        "totalPaid": 100,
        "investorOnly": 0,
    }
    sharedItemOwner = _stubs_data.CreateBulk(objs = [ obj ], collectionName = 'sharedItemOwner',
        saveInDatabase = 0)[0]
    # sharedItemOwner = {
    #     "sharedItemId": sharedItem['_id'],
    #     "userId": user['_id'],
    #     "generation": 1,
    #     "monthlyPayment": 50,
    #     "totalPaid": 100,
    #     "totalOwed": 0,
    #     "investorOnly": 0,
    # }
    ret = _shared_item_owner.Save(sharedItemOwner)
    query = {
        'userId': sharedItemOwner['userId'],
        'forType': 'sharedItemOwner',
        'forId': ret['sharedItemOwner']['_id'],
    }
    userPayment = mongo_db.find_one('userPayment', query)['item']
    assert userPayment['status'] == 'pending'
    assert userPayment['amountUSD'] == -1 * sharedItemOwner['totalPaid']

    # Since pending, should not have any user balance yet.
    query = {
        'userId': sharedItemOwner['userId'],
    }
    userMoney = mongo_db.find_one('userMoney', query)['item']
    assert userMoney is None

    _mongo_mock.CleanUp()
