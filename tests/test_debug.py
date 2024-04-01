import mongo_mock as _mongo_mock
from notifications_all import sms_twilio as _sms_twilio
def test_Debug():
    _mongo_mock.InitAllCollections()
    ret = _sms_twilio.Send("Here's your first text!", "+19252869131")
    assert ret['valid'] == 1
    _mongo_mock.CleanUp()
