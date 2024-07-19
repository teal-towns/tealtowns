from notifications_all import sms_twilio as sms_twilio

def test_AddPrefix():
    assert sms_twilio.AddPrefix('123', '') == '+123'
    assert sms_twilio.AddPrefix('+123', '') == '+123'
    assert sms_twilio.AddPrefix('123', 'whatsapp') == 'whatsapp:+123'
    assert sms_twilio.AddPrefix('+123', 'whatsapp') == 'whatsapp:+123'
    assert sms_twilio.AddPrefix('whatsapp:+123', 'whatsapp') == 'whatsapp:+123'
    assert sms_twilio.AddPrefix('123', 'whatsapp:') == 'whatsapp:+123'
