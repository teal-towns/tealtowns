import mongo_mock as _mongo_mock
from shared_item import shared_item as _shared_item
from stubs import stubs_data as _stubs_data

def test_Save():
    _mongo_mock.InitAllCollections()

    # Should make user an owner.
    sharedItem = {
        'status': 'available',
        'generation': 0,
        'currentGenerationStart': '',
        'currentOwnerUserId': 'userId1'
    }
    sharedItem = _stubs_data.CreateBulk(count = 1, collectionName = 'sharedItem', saveInDatabase = 0)[0]

    ret = _shared_item.Save(sharedItem)
    assert ret['sharedItemOwner']['sharedItemId'] == ret['sharedItem']['_id']
    assert ret['sharedItemOwner']['generation'] == sharedItem['generation'] + 1
    assert ret['sharedItemOwner']['userId'] == sharedItem['currentOwnerUserId']

    assert ret['sharedItem']['pledgedOwners'] == 1

    _mongo_mock.CleanUp()
