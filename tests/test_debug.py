import mongo_mock as _mongo_mock
from notifications_all import sms_twilio as _sms_twilio
def test_Debug():
    # _mongo_mock.InitAllCollections()
    _mongo_mock.InitLive()
    ret = _sms_twilio.Send("Here's your first text!", "+19252869131")
    assert ret['valid'] == 1
    # _mongo_mock.CleanUp()

    # _mongo_mock.InitLive()
    # from common import mongo_db_crud as _mongo_db_crud
    # retUsers = _mongo_db_crud.Search('user', { 'firstName': 'Luke' })
    # print ('retUsers', retUsers)
    # from user_payment import user_payment as _user_payment
    # _user_payment.AddPayment('65240f968828bbab8f2873b1', 1000, 'test', '')

