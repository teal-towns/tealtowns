import mongo_mock as _mongo_mock
import mongo_db
from neighborhood import user_neighborhood as _user_neighborhood
from stubs import stubs_data as _stubs_data

def test_Save():
    _mongo_mock.InitAllCollections()
    users = _stubs_data.CreateBulk(count = 1, collectionName = 'user')
    userNeighborhood = { 'userId': users[0]['_id'], 'neighborhoodUName': 'neighborhood1', 'status': 'default', 'motivations': [], }
    ret = _user_neighborhood.Save(userNeighborhood)
    userNeighborhoods = mongo_db.find('userNeighborhood', {'userId': users[0]['_id']})['items']
    assert len(userNeighborhoods) == 1
    assert userNeighborhoods[0]['status'] == 'default'

    # Add second neighborhood
    userNeighborhood = { 'userId': users[0]['_id'], 'neighborhoodUName': 'neighborhood2', 'status': 'default', 'motivations': [], }
    _user_neighborhood.Save(userNeighborhood)
    userNeighborhoods = mongo_db.find('userNeighborhood', {'userId': users[0]['_id']})['items']
    assert len(userNeighborhoods) == 2
    for item in userNeighborhoods:
        if item['neighborhoodUName'] == 'neighborhood1':
            assert item['status'] == ''
        if item['neighborhoodUName'] == 'neighborhood2':
            assert item['status'] == 'default'
    
    # Re-make neighborhood 1 default.
    userNeighborhood = { 'userId': users[0]['_id'], 'neighborhoodUName': 'neighborhood1', 'status': 'default', 'motivations': [], }
    _user_neighborhood.Save(userNeighborhood)
    userNeighborhoods = mongo_db.find('userNeighborhood', {'userId': users[0]['_id']})['items']
    assert len(userNeighborhoods) == 2
    for item in userNeighborhoods:
        if item['neighborhoodUName'] == 'neighborhood1':
            assert item['status'] == 'default'
        if item['neighborhoodUName'] == 'neighborhood2':
            assert item['status'] == ''

    _mongo_mock.CleanUp()
