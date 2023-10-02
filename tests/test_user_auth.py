import mongo_mock as _mongo_mock
import user_auth as _user_auth
import stubs_user as _stubs_user

def test_signup():
    _mongo_mock.InitAllCollections()
    # _mongo_mock.GetCollection('user')
    user = { 'email': 'joe@email.com', 'password': 'pass1', 'firstName': 'Joe', 'lastName': 'Johnson' }
    retUser = _user_auth.signup(user['email'], user['password'], user['firstName'], user['lastName'])
    retGet = _user_auth.getByEmail(user['email'])
    assert retGet['_id'] == retUser['user']['_id']
    assert retGet['email'] == user['email']

def test_updateFirstLastName():
    _mongo_mock.InitAllCollections()
    users = _stubs_user.GetAll()
    retUser = _stubs_user.CreateUser(users[0])
    user = retUser['user']
    firstName = 'Joe'
    lastName = 'Johnson'
    retNewUser = _user_auth.updateFirstLastName(user, firstName, lastName)['user']
    assert retNewUser['_id'] == retUser['user']['_id']
    assert retNewUser['email'] == user['email']
    assert retNewUser['firstName'] == firstName
    assert retNewUser['lastName'] == lastName