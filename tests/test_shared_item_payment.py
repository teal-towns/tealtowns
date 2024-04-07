import date_time
import lodash
import mongo_mock as _mongo_mock
import mongo_db
from shared_item import shared_item as _shared_item
from shared_item import shared_item_owner as _shared_item_owner
from shared_item import shared_item_payment as _shared_item_payment
from shared_item import shared_item_payment_math as _shared_item_payment_math
from stubs import stubs_data as _stubs_data

# def test_CanStartPurchase_byPledgedOwners():
#     _mongo_mock.InitAllCollections()

#     users = _stubs_data.CreateBulk(count = 3, collectionName = 'user')
#     # First user creates item.
#     sharedItem = {
#         'status': 'available',
#         'generation': 0,
#         'currentGenerationStart': '',
#         'currentOwnerUserId': users[0]['_id'],
#         'bought': 1,
#     }
#     sharedItem = _stubs_data.CreateBulk(count = 1, collectionName = 'sharedItem', saveInDatabase = 0)[0]
#     ret = _shared_item.Save(sharedItem)
#     assert ret['sharedItemOwner']['sharedItemId'] == ret['sharedItem']['_id']
#     assert ret['sharedItemOwner']['generation'] == sharedItem['generation'] + 1
#     assert ret['sharedItemOwner']['userId'] == sharedItem['currentOwnerUserId']

#     assert ret['sharedItem']['pledgedOwners'] == 1

#     _mongo_mock.CleanUp()

# def test_CanStartPurchase_byFunding():

def test_StartPurchase_byOwners():
    _mongo_mock.InitAllCollections()

    users = _stubs_data.CreateBulk(count = 5, collectionName = 'user')
    sharedItemBase = {
        'status': 'available',
        'generation': 0,
        'currentGenerationStart': '',
        'currentOwnerUserId': users[0]['_id'],
        'bought': 1,
        'currentPrice': 1000,
        'minOwners': 3,
        'monthsToPayBack': 12,
        'maintenancePerYear': 50,
    }
    sharedItemOwnerBase = {
        'generation': sharedItemBase['generation'] + 1,
        'investorOnly': 0,
    }

    sharedItem = _stubs_data.CreateBulk([ sharedItemBase ], collectionName = 'sharedItem', saveInDatabase = 0)[0]
    ret = _shared_item.Save(sharedItem)
    sharedItem = ret['sharedItem']

    paymentInfo = _shared_item_payment_math.GetPayments(sharedItem['currentPrice'], sharedItem['monthsToPayBack'],
        sharedItem['minOwners'], sharedItem['maintenancePerYear'])

    # Creator should be a pledged owner and since bought, should have no funding required.
    assert ret['sharedItem']['pledgedOwners'] == 1
    assert ret['sharedItem']['fundingRequired'] == 0
    # Should NOT have any new pending payment, since already bought.
    query = {
        'userId': users[0]['_id'],
        'forType': 'sharedItemOwner',
        'forId': ret['sharedItemOwner']['_id'],
        'status': 'pending',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 0

    # Make high so it will have enough purchase owners as soon as min owners is reached.
    sharedItemOwner = lodash.extend_object(sharedItemOwnerBase, {
        'sharedItemId': ret['sharedItem']['_id'],
        'userId': users[1]['_id'],
        'totalPaid': paymentInfo['downPerPerson'],
        'monthlyPayment': paymentInfo['monthlyPayment'],
    })
    sharedItemOwner = _stubs_data.CreateBulk(objs = [ sharedItemOwner ], collectionName = 'sharedItemOwner', saveInDatabase = 0)[0]
    sharedItemOwner1 = _shared_item_owner.Save(sharedItemOwner)['sharedItemOwner']
    # Should have a pending payment.
    query = {
        'userId': users[1]['_id'],
        'forType': 'sharedItemOwner',
        'forId': sharedItemOwner1['_id'],
        'status': 'pending',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 1
    assert userPayments[0]['amountUSD'] == -1 * sharedItemOwner1['totalPaid']

    sharedItemTemp = mongo_db.find_one('sharedItem', { '_id': ret['sharedItem']['_id'] })['item']
    assert sharedItemTemp['pledgedOwners'] == 2
    # 2 owners; not over min owners yet.
    purchaseOwners = _shared_item_payment.GetPurchaseOwners(sharedItemTemp)
    assert len(purchaseOwners) == 0

    sharedItemOwner = lodash.extend_object(sharedItemOwnerBase, {
        'sharedItemId': ret['sharedItem']['_id'],
        'userId': users[2]['_id'],
        'totalPaid': paymentInfo['downPerPerson'],
        'monthlyPayment': paymentInfo['monthlyPayment'],
    })
    sharedItemOwner = _stubs_data.CreateBulk(objs = [ sharedItemOwner ], collectionName = 'sharedItemOwner', saveInDatabase = 0)[0]
    # 3 owners, so should trigger starting purchase.
    sharedItemOwner2 = _shared_item_owner.Save(sharedItemOwner)['sharedItemOwner']
    # The pending payment should have been created and then completed.
    # Check that all payments are complete and one more was added for each owner (to purchaser).
    query = {
        'userId': { '$in': [ users[1]['_id'], users[2]['_id'] ] },
        'forType': 'sharedItemOwner',
        'status': 'complete',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 2
    # Confirm purchaser was paid.
    query = {
        'userId': users[0]['_id'],
        'forType': 'sharedItemOwner',
        'status': 'complete',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 2

    # Check user balances.
    query = {
        'userId': { '$in': [ users[0]['_id'], users[1]['_id'], users[2]['_id'] ] },
    }
    userMoneys = mongo_db.find('userMoney', query)['items']
    for userMoney in userMoneys:
        if userMoney['userId'] == users[0]['_id']:
            assert userMoney['balanceUSD'] == sharedItemOwner1['totalPaid'] + sharedItemOwner2['totalPaid']
        elif userMoney['userId'] == users[1]['_id']:
            withCut = _shared_item_payment_math.AddFee(sharedItemOwner1['totalPaid'], withPayFee = 0)
            assert userMoney['balanceUSD'] == -1 * withCut
        elif userMoney['userId'] == users[2]['_id']:
            withCut = _shared_item_payment_math.AddFee(sharedItemOwner2['totalPaid'], withPayFee = 0)
            assert userMoney['balanceUSD'] == -1 * withCut

    sharedItemNew = mongo_db.find_one('sharedItem', { '_id': ret['sharedItem']['_id'] })['item']
    assert sharedItemNew['currentPurchaserUserId'] == users[0]['_id']
    assert sharedItemNew['status'] == 'owned'
    assert sharedItemNew['generation'] == sharedItem['generation'] + 1

    # Check shared item owned.
    query = {
        'userId': { '$in': [ users[0]['_id'], users[1]['_id'], users[2]['_id'] ] },
        'sharedItemId': sharedItem['_id'],
    }
    sharedItemOwners = mongo_db.find('sharedItemOwner', query)['items']
    assert len(sharedItemOwners) == 3
    for item in sharedItemOwners:
        assert item['generation'] == sharedItemNew['generation']
        if item['userId'] == users[0]['_id']:
            assert item['totalOwed'] == -1 * paymentInfo['totalToPayBack']
            assert item['totalPaidBack'] == sharedItemOwner1['totalPaid'] + sharedItemOwner2['totalPaid']
            assert item['status'] == 'paid'
        else:
            assert item['totalOwed'] == paymentInfo['totalPerPerson']
            if paymentInfo['monthsToPayBack'] > 0:
                assert item['status'] == 'pendingMonthlyPayment'
            else:
                assert item['status'] == 'paid'

    _mongo_mock.CleanUp()

def test_StartPurchase_byFunding():
    _mongo_mock.InitAllCollections()

    users = _stubs_data.CreateBulk(count = 5, collectionName = 'user')
    sharedItemBase = {
        'status': 'available',
        'generation': 0,
        'currentGenerationStart': '',
        'currentOwnerUserId': users[0]['_id'],
        'bought': 0,
        'currentPrice': 1000,
        'minOwners': 3,
        'monthsToPayBack': 12,
        'maintenancePerYear': 50,
    }
    sharedItemOwnerBase = {
        'generation': sharedItemBase['generation'] + 1,
        'investorOnly': 0,
    }

    sharedItem = _stubs_data.CreateBulk([ sharedItemBase ], collectionName = 'sharedItem', saveInDatabase = 0)[0]
    ret = _shared_item.Save(sharedItem)
    sharedItem = ret['sharedItem']

    paymentInfo = _shared_item_payment_math.GetPayments(sharedItem['currentPrice'], sharedItem['monthsToPayBack'],
        sharedItem['minOwners'], sharedItem['maintenancePerYear'])

    sharedItemOwner0 = ret['sharedItemOwner']
    assert sharedItemOwner0['totalPaid'] == paymentInfo['downPerPerson']
    assert sharedItemOwner0['monthlyPayment'] == paymentInfo['monthlyPayment']
    assert sharedItemOwner0['totalOwed'] == paymentInfo['totalPerPerson']

    # Creator should be a pledged owner.
    assert ret['sharedItem']['pledgedOwners'] == 1
    assert ret['sharedItem']['fundingRequired'] == sharedItem['currentPrice'] - paymentInfo['downPerPerson']
    # Should have pending payment, since NOT bought.
    query = {
        'userId': users[0]['_id'],
        'forType': 'sharedItemOwner',
        'forId': ret['sharedItemOwner']['_id'],
        'status': 'pending',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 1

    # Make high so it will have enough purchase owners as soon as min owners is reached.
    sharedItemOwner = lodash.extend_object(sharedItemOwnerBase, {
        'sharedItemId': ret['sharedItem']['_id'],
        'userId': users[1]['_id'],
        'totalPaid': paymentInfo['downPerPerson'],
        'monthlyPayment': paymentInfo['monthlyPayment'],
    })
    sharedItemOwner = _stubs_data.CreateBulk(objs = [ sharedItemOwner ], collectionName = 'sharedItemOwner', saveInDatabase = 0)[0]
    sharedItemOwner1 = _shared_item_owner.Save(sharedItemOwner)['sharedItemOwner']
    # Should have a pending payment.
    query = {
        'userId': users[1]['_id'],
        'forType': 'sharedItemOwner',
        'forId': sharedItemOwner1['_id'],
        'status': 'pending',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 1
    assert userPayments[0]['amountUSD'] == -1 * sharedItemOwner1['totalPaid']

    sharedItemTemp = mongo_db.find_one('sharedItem', { '_id': ret['sharedItem']['_id'] })['item']
    assert sharedItemTemp['pledgedOwners'] == 2
    # 2 owners; not over min owners yet.
    purchaseOwners = _shared_item_payment.GetPurchaseOwners(sharedItemTemp)
    assert len(purchaseOwners) == 0

    sharedItemOwner = lodash.extend_object(sharedItemOwnerBase, {
        'sharedItemId': ret['sharedItem']['_id'],
        'userId': users[2]['_id'],
        'totalPaid': paymentInfo['downPerPerson'],
        'monthlyPayment': paymentInfo['monthlyPayment'],
    })
    sharedItemOwner = _stubs_data.CreateBulk(objs = [ sharedItemOwner ], collectionName = 'sharedItemOwner', saveInDatabase = 0)[0]
    # 3 owners, so over min BUT not funded yet, so should not start purchase.
    sharedItemOwner2 = _shared_item_owner.Save(sharedItemOwner)['sharedItemOwner']
    # Should have a pending payment.
    query = {
        'userId': users[2]['_id'],
        'forType': 'sharedItemOwner',
        'forId': sharedItemOwner2['_id'],
        'status': 'pending',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 1
    assert userPayments[0]['amountUSD'] == -1 * sharedItemOwner2['totalPaid']

    sharedItemTemp = mongo_db.find_one('sharedItem', { '_id': ret['sharedItem']['_id'] })['item']
    assert sharedItemTemp['pledgedOwners'] == 3
    # 3 owners; over min owners.
    purchaseOwners = _shared_item_payment.GetPurchaseOwners(sharedItemTemp)
    assert len(purchaseOwners) == 3


    # Add funder.
    sharedItemOwner = lodash.extend_object(sharedItemOwnerBase, {
        'sharedItemId': ret['sharedItem']['_id'],
        'userId': users[3]['_id'],
        'totalPaid': sharedItem['currentPrice'],
        'monthlyPayment': 0,
        'investorOnly': 1,
    })
    sharedItemOwner = _stubs_data.CreateBulk(objs = [ sharedItemOwner ], collectionName = 'sharedItemOwner', saveInDatabase = 0)[0]
    # 3 owners, so over min BUT not funded yet, so should not start purchase.
    sharedItemOwner3 = _shared_item_owner.Save(sharedItemOwner)['sharedItemOwner']

    # Check that all payments are complete and one more was added for each owner (to purchaser).
    query = {
        'userId': { '$in': [ users[0]['_id'], users[1]['_id'], users[2]['_id'] ] },
        'forType': 'sharedItemOwner',
        'status': 'complete',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 3
    # Confirm purchaser was paid.
    query = {
        'userId': users[3]['_id'],
        'forType': 'sharedItemOwner',
        'status': 'complete',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 3

    # Check user balances.
    query = {
        'userId': { '$in': [ users[0]['_id'], users[1]['_id'], users[2]['_id'], users[3]['_id'] ] },
    }
    userMoneys = mongo_db.find('userMoney', query)['items']
    for userMoney in userMoneys:
        if userMoney['userId'] == users[0]['_id']:
            withCut = _shared_item_payment_math.AddFee(sharedItemOwner0['totalPaid'], withPayFee = 0)
            assert userMoney['balanceUSD'] == -1 * withCut
        elif userMoney['userId'] == users[1]['_id']:
            withCut = _shared_item_payment_math.AddFee(sharedItemOwner1['totalPaid'], withPayFee = 0)
            assert userMoney['balanceUSD'] == -1 * withCut
        elif userMoney['userId'] == users[2]['_id']:
            withCut = _shared_item_payment_math.AddFee(sharedItemOwner2['totalPaid'], withPayFee = 0)
            assert userMoney['balanceUSD'] == -1 * withCut
        elif userMoney['userId'] == users[3]['_id']:
            assert userMoney['balanceUSD'] == sharedItemOwner1['totalPaid'] + sharedItemOwner2['totalPaid'] \
                + sharedItemOwner0['totalPaid']

    sharedItemNew = mongo_db.find_one('sharedItem', { '_id': ret['sharedItem']['_id'] })['item']
    assert sharedItemNew['currentPurchaserUserId'] == users[3]['_id']
    assert sharedItemNew['status'] == 'purchasing'
    assert sharedItemNew['generation'] == sharedItem['generation'] + 1

    # Check shared item owned.
    query = {
        'userId': { '$in': [ users[0]['_id'], users[1]['_id'], users[2]['_id'], users[3]['_id'] ] },
        'sharedItemId': sharedItem['_id'],
    }
    sharedItemOwners = mongo_db.find('sharedItemOwner', query)['items']
    assert len(sharedItemOwners) == 4
    for item in sharedItemOwners:
        assert item['generation'] == sharedItemNew['generation']
        if item['userId'] == users[3]['_id']:
            assert item['totalOwed'] == -1 * paymentInfo['totalToPayBack']
            assert item['totalPaidBack'] == sharedItemOwner1['totalPaid'] + sharedItemOwner2['totalPaid'] + \
                sharedItemOwner0['totalPaid']
            assert item['status'] == 'paid'
        else:
            assert item['totalOwed'] == paymentInfo['totalPerPerson']
            if paymentInfo['monthsToPayBack'] > 0:
                assert item['status'] == 'pendingMonthlyPayment'
            else:
                assert item['status'] == 'paid'


    # Set up monthly payment
    # Delay 2 months; amount should be more.
    now = date_time.nextMonth(date_time.from_string(sharedItemNew['currentGenerationStart']), months = 2)
    retMonthly = _shared_item_payment.ComputeMonthlyPaymentAmount(sharedItemOwner1['_id'], now = now)
    assert retMonthly['monthsRemaining'] <= paymentInfo['monthsToPayBack'] - 2
    assert retMonthly['monthlyPayment'] > paymentInfo['monthlyPayment']

    # Make future (monthly) payments.
    query = {
        'userId': users[3]['_id'],
    }
    userMoney3Before = mongo_db.find_one('userMoney', query)['item']
    query = {
        '_id': mongo_db.to_object_id(sharedItemOwner3['_id']),
    }
    sharedItemOwner3Before = mongo_db.find_one('sharedItemOwner', query)['item']
    _shared_item_payment.MakeOwnerPayment(sharedItemOwner1['_id'], paymentInfo['monthlyPayment'])
    # Should have 2 payments now; one for down payment and one for monthly.
    query = {
        'userId': users[1]['_id'],
        'forType': 'sharedItemOwner',
        'status': 'complete',
    }
    userPayments = mongo_db.find('userPayment', query)['items']
    assert len(userPayments) == 2
    # Check money.
    query = {
        'userId': sharedItemOwner1['userId'],
    }
    userMoney = mongo_db.find_one('userMoney', query)['item']
    totalPaid1 = paymentInfo['downPerPerson'] + paymentInfo['monthlyPayment']
    withCut = _shared_item_payment_math.AddFee(totalPaid1, withPayFee = 0)
    assert userMoney['balanceUSD'] == -1 * withCut
    # Check shared item owner.
    sharedItemOwnerTemp = mongo_db.find_one('sharedItemOwner', { '_id': sharedItemOwner1['_id'] })['item']
    assert sharedItemOwnerTemp['totalPaid'] == totalPaid1

    # Check that purchaser was paid.
    query = {
        'userId': users[3]['_id'],
    }
    userMoney3After = mongo_db.find_one('userMoney', query)['item']
    assert userMoney3After['balanceUSD'] == userMoney3Before['balanceUSD'] + paymentInfo['monthlyPayment']
    # Check shared item owner.
    query = {
        '_id': mongo_db.to_object_id(sharedItemOwner3['_id']),
    }
    sharedItemOwner3After = mongo_db.find_one('sharedItemOwner', query)['item']
    assert sharedItemOwner3After['totalPaidBack'] == sharedItemOwner3Before['totalPaidBack'] + paymentInfo['monthlyPayment']

    _mongo_mock.CleanUp()