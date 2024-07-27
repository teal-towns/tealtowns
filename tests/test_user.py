from user_auth import user as _user

def test_GuessContactType():
    ret = _user.GuessContactType('1-555-123-4567')
    assert ret == 'phone'

    ret = _user.GuessContactType('15551234567')
    assert ret == 'phone'

    ret = _user.GuessContactType('2rHv0@example.com')
    assert ret == 'email'

    ret = _user.GuessContactType('test')
    assert ret == ''
