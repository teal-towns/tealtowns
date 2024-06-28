import date_time
import mongo_db
import mongo_mock as _mongo_mock
from stubs import stubs_data as _stubs_data
from pay_mercury import pay_mercury as _pay_mercury

def test_QueueAndDoTransactions():
    _mongo_mock.InitAllCollections()
    # Queue pay outs with various date times.
    mercuryPayOuts = [
        { 'createdAt': '2024-04-01T17:00:00+00:00' },
        { 'createdAt': '2024-04-03T17:00:00+00:00' },
        { 'createdAt': '2024-04-05T17:00:00+00:00' },
        { 'createdAt': '2024-04-07T17:00:00+00:00' },
        { 'createdAt': '2024-04-09T17:00:00+00:00' },
    ]
    accountKey = 'MercuryEndUserFunds'
    recipientKey = 'MercuryUserRevenue'
    default = { 'accountKey': accountKey, 'recipientKey': recipientKey }
    transactionKey = accountKey + '_' + recipientKey
    mercuryPayOuts = _stubs_data.CreateBulk(objs = mercuryPayOuts, default = default,
        collectionName = 'mercuryPayOut', saveInDatabase = 0)
    for index, mercuryPayOut in enumerate(mercuryPayOuts):
        ret = _pay_mercury.QueueTransaction(mercuryPayOut['accountKey'], mercuryPayOut['recipientKey'],
            mercuryPayOut['amountUSD'], mercuryPayOut['forId'], mercuryPayOut['forType'],
            now = date_time.from_string(mercuryPayOut['createdAt']))
        mercuryPayOuts[index] = ret['mercuryPayOut']

    # Before 7 days after - no transactions yet.
    now = date_time.from_string('2024-04-07T15:00:00+00:00')
    ret = _pay_mercury.CheckDoQueuedTransactions(now = now)
    assert ret['paidOutIds'] == []
    assert ret['amountUSDByKey'] == {}
    newPayOuts = mongo_db.find('mercuryPayOut', { 'paidOut': 1 })['items']
    assert len(newPayOuts) == 0

    now = date_time.from_string('2024-04-11T15:00:00+00:00')
    ret = _pay_mercury.CheckDoQueuedTransactions(now = now)
    assert ret['paidOutIds'] == [mercuryPayOuts[0]['_id'], mercuryPayOuts[1]['_id']]
    assert ret['amountUSDByKey'][transactionKey] == mercuryPayOuts[0]['amountUSD'] + mercuryPayOuts[1]['amountUSD']
    newPayOuts = mongo_db.find('mercuryPayOut', { 'paidOut': 1 })['items']
    assert len(newPayOuts) == 2
    for newPayOut in newPayOuts:
        assert newPayOut['_id'] in [mercuryPayOuts[0]['_id'], mercuryPayOuts[1]['_id']]

    now = date_time.from_string('2024-04-17T15:00:00+00:00')
    ret = _pay_mercury.CheckDoQueuedTransactions(now = now)
    assert ret['paidOutIds'] == [mercuryPayOuts[2]['_id'], mercuryPayOuts[3]['_id'], mercuryPayOuts[4]['_id']]
    assert ret['amountUSDByKey'][transactionKey] == mercuryPayOuts[2]['amountUSD'] + mercuryPayOuts[3]['amountUSD'] + mercuryPayOuts[4]['amountUSD']
    newPayOuts = mongo_db.find('mercuryPayOut', { 'paidOut': 1 })['items']
    assert len(newPayOuts) == 5
    # for newPayOut in newPayOuts:
    #     assert newPayOut['_id'] in [mercuryPayOuts[0]['_id']]

    _mongo_mock.CleanUp()
