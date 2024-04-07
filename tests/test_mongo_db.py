import mongo_mock as _mongo_mock
import mongo_db

def test_Validate():
    _mongo_mock.InitAllCollections()
    user = {
        'email': 'JUv3d@example.com',
        'badKey': '',
    }
    ret = mongo_db.Validate('user', user, allowPartial = 1)
    assert ret['item'] == {
        'email': 'JUv3d@example.com',
    }
    assert ret['removedFields'] == ['badKey']
    _mongo_mock.CleanUp()
