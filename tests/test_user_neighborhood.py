import mongo_mock as _mongo_mock
import mongo_db
from neighborhood import user_neighborhood as _user_neighborhood

def test_Save():
    _mongo_mock.InitAllCollections()
    userNeighborhood = { 'userId': 'user1', 'neighborhoodUName': 'neighborhood1', 'status': 'default', 'motivations': [], }
    _user_neighborhood.Save(userNeighborhood)
    userNeighborhoods = mongo_db.find('userNeighborhood', {'userId': 'user1'})['items']
    assert len(userNeighborhoods) == 1
    assert userNeighborhoods[0]['status'] == 'default'

    # Add second neighborhood
    userNeighborhood = { 'userId': 'user1', 'neighborhoodUName': 'neighborhood2', 'status': 'default', 'motivations': [], }
    _user_neighborhood.Save(userNeighborhood)
    userNeighborhoods = mongo_db.find('userNeighborhood', {'userId': 'user1'})['items']
    assert len(userNeighborhoods) == 2
    for item in userNeighborhoods:
        if item['neighborhoodUName'] == 'neighborhood1':
            assert item['status'] == ''
        if item['neighborhoodUName'] == 'neighborhood2':
            assert item['status'] == 'default'
    
    # Re-make neighborhood 1 default.
    userNeighborhood = { 'userId': 'user1', 'neighborhoodUName': 'neighborhood1', 'status': 'default', 'motivations': [], }
    _user_neighborhood.Save(userNeighborhood)
    userNeighborhoods = mongo_db.find('userNeighborhood', {'userId': 'user1'})['items']
    assert len(userNeighborhoods) == 2
    for item in userNeighborhoods:
        if item['neighborhoodUName'] == 'neighborhood1':
            assert item['status'] == 'default'
        if item['neighborhoodUName'] == 'neighborhood2':
            assert item['status'] == ''

    _mongo_mock.CleanUp()
