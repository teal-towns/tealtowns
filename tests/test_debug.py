import json

import mongo_mock as _mongo_mock

def test_Debug():
    # _mongo_mock.InitAllCollections()
    # _mongo_mock.InitLive()
    # from notifications_all import sms_twilio as _sms_twilio
    # ret = _sms_twilio.Send("Here's your first text!", "+19252869131")
    # assert ret['valid'] == 1
    # _mongo_mock.CleanUp()

    # _mongo_mock.InitLive()
    # from common import mongo_db_crud as _mongo_db_crud
    # retUsers = _mongo_db_crud.Search('user', { 'firstName': 'Luke' })
    # print ('retUsers', retUsers)
    # from user_payment import user_payment as _user_payment
    # _user_payment.AddPayment('65240f968828bbab8f2873b1', 1000, 'test', '')

    # import mongo_db
    # _mongo_mock.InitLive()
    # item = mongo_db.find_one('sharedItem', { '_id': mongo_db.to_object_id('65d3f813f26d294ad0ec38c9') })['item']
    # print ('item', item)
    # from common import mongo_db_crud as _mongo_db_crud
    # retItems = _mongo_db_crud.Search('sharedItem', { 'title': 'compost' })
    # print ('retItems', len(retItems['sharedItems']), retItems)

    # from neighborhood import certification_level_import as _certification_level_import
    # _mongo_mock.InitLive()
    # _certification_level_import.ImportToDB()

    # from pay_mercury import pay_mercury as _pay_mercury
    # ret = _pay_mercury.MakeRequest('post', 'recipients', params)
    # ret = _pay_mercury.MakeRequest('get', 'recipients')
    # ret = _pay_mercury.GetAndAddRecipients()
    # print ('ret', ret)
    # print (json.dumps(_pay_mercury.GetAccounts(), indent = 2))
    # ret = _pay_mercury.MakeTransaction('MainTemp', 'MercuryUserRevenue', 0.11, 'testOne')
    # print ('ret', ret)

    # import mongo_db
    # user = mongo_db.find_one('user', { 'email': 'luke.madera@gmail.com' })['item']
    # print ('\nuser', user)
    # # subscription = mongo_db.find_one('userPaymentSubscription', { 'userId': user['_id']} )['item']
    # # print ('subscription', subscription)
    # weeklyEvent = mongo_db.find_one('weeklyEvent', { 'uName': 'qhozm' })['item']
    # print ('\nweeklyEvent', weeklyEvent)
    # events = mongo_db.find('event', { 'weeklyEventId': weeklyEvent['_id'] })['items']
    # print ('\nevents', events)
    # eventIds = [ event['_id'] for event in events ]
    # userEvents = mongo_db.find('userEvent', { 'userId': user['_id'], 'eventId': { '$in': eventIds} })['items']
    # print ('\nuserEvents', userEvents)
    # userEvent = mongo_db.find_one('userEvent', { 'eventId': events[0]['_id'], 'userId': user['_id'] })['item']
    # print ('\nuserEvent', userEvent)
    pass
