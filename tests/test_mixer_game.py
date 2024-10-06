import mongo_db
import mongo_mock as _mongo_mock
from stubs import stubs_data as _stubs_data
from mixer import mixer_game as _mixer_game
from mixer import mixer_match_player as _mixer_match_player
import websocket_clients as _websocket_clients

def test_MixerGame():
    _mongo_mock.InitAllCollections()

    users = _stubs_data.CreateBulk(count = 3, collectionName = 'user')
    mixerMatchPlayers = [
        { 'name': 'Anne', 'answer': 'Blue', },
        { 'userId': users[1]['_id'], 'name': 'Bob', 'answer': 'Red', },
        { 'userId': users[2]['_id'], 'name': 'Cathy', 'answer': 'Green', },
        { 'name': 'David', 'answer': 'Yellow', },
        { 'userId': users[0]['_id'], 'name': 'Eve', 'answer': 'Yellow', },
        { 'name': 'Fred', 'answer': 'Purple', },
    ]
    # User 0 creates game as host.
    mixerGame = {
        'neighborhoodUName': 'neighborhood1',
        'gameType': 'match',
        'hostUserIds': [users[0]['_id']],
        'gameDetails': { 'question': 'Favorite color?' },
    }
    ret = _mixer_game.Save(mixerGame)
    assert ret['valid'] == 1
    assert ret['mixerGame']['state'] == 'playing'
    assert ret['mixerGame']['hostUserIds'] == [users[0]['_id']]
    assert ret['mixerGame']['players'] == []
    mixerGame = ret['mixerGame']
    uName = mixerGame['uName']
    socketGroupName = 'mixerGame_' + uName

    for index, mixerMatchPlayer in enumerate(mixerMatchPlayers):
        mixerMatchPlayers[index]['mixerGameUName'] = ret['mixerGame']['uName']

    ws = {}
    # Player 0 joins game
    ret = _mixer_match_player.Save(mixerMatchPlayers[0], websocket = ws)
    mixerMatchPlayers[0]['_id'] = ret['mixerMatchPlayer']['_id']
    assert ret['valid'] == 1
    assert ret['socketGroupName'] == socketGroupName
    assert len(ret['mixerMatchPlayers']) == 1
    mixerGameTemp = mongo_db.find_one('mixerGame', { 'uName': uName })['item']
    assert len(mixerGameTemp['players']) == 1
    userIds = _websocket_clients.GetUserIdsInGroup(socketGroupName)
    assert len(userIds) == 1

    ret = _mixer_match_player.Save(mixerMatchPlayers[1], websocket = ws)
    mixerMatchPlayers[1]['_id'] = ret['mixerMatchPlayer']['_id']
    assert len(ret['mixerMatchPlayers']) == 2
    userIds = _websocket_clients.GetUserIdsInGroup(socketGroupName)
    assert len(userIds) == 2

    ret = _mixer_match_player.Save(mixerMatchPlayers[2], websocket = ws)
    mixerMatchPlayers[2]['_id'] = ret['mixerMatchPlayer']['_id']
    assert len(ret['mixerMatchPlayers']) == 3
    userIds = _websocket_clients.GetUserIdsInGroup(socketGroupName)
    assert len(userIds) == 3

    ret = _mixer_match_player.Save(mixerMatchPlayers[3], websocket = ws)
    mixerMatchPlayers[3]['_id'] = ret['mixerMatchPlayer']['_id']
    assert len(ret['mixerMatchPlayers']) == 4
    userIds = _websocket_clients.GetUserIdsInGroup(socketGroupName)
    assert len(userIds) == 4

    ret = _mixer_match_player.Save(mixerMatchPlayers[4], websocket = ws)
    mixerMatchPlayers[4]['_id'] = ret['mixerMatchPlayer']['_id']
    assert len(ret['mixerMatchPlayers']) == 5
    userIds = _websocket_clients.GetUserIdsInGroup(socketGroupName)
    assert len(userIds) == 5

    ret = _mixer_match_player.Save(mixerMatchPlayers[5], websocket = ws)
    mixerMatchPlayers[5]['_id'] = ret['mixerMatchPlayer']['_id']
    assert len(ret['mixerMatchPlayers']) == 6
    mixerGameTemp = mongo_db.find_one('mixerGame', { 'uName': uName })['item']
    assert len(mixerGameTemp['players']) == 6
    userIds = _websocket_clients.GetUserIdsInGroup(socketGroupName)
    assert len(userIds) == 6

    # Host ends game
    ret = _mixer_game.Save({ '_id': mixerGame['_id'], 'state': 'gameOver' })
    assert ret['valid'] == 1

    # Players submit scores
    ret = _mixer_game.UpdatePlayerScore(uName, { 'playerId': mixerMatchPlayers[0]['_id'], 'score': 1, })
    mixerGameTemp = mongo_db.find_one('mixerGame', { 'uName': uName })['item']
    submittedCount = 0
    for player in mixerGameTemp['players']:
        assert player['reward'] == ''
        if player['playerId'] == mixerMatchPlayers[0]['_id']:
            assert player['score'] == 1
            assert player['scoreState'] == 'submitted'
        if player['scoreState'] == 'submitted':
            submittedCount += 1
    assert submittedCount == 1

    ret = _mixer_game.UpdatePlayerScore(uName, { 'playerId': mixerMatchPlayers[1]['_id'], 'score': 5, })
    mixerGameTemp = mongo_db.find_one('mixerGame', { 'uName': uName })['item']
    submittedCount = 0
    for player in mixerGameTemp['players']:
        assert player['reward'] == ''
        if player['playerId'] == mixerMatchPlayers[1]['_id']:
            assert player['score'] == 5
            assert player['scoreState'] == 'submitted'
        if player['scoreState'] == 'submitted':
            submittedCount += 1
    assert submittedCount == 2

    ret = _mixer_game.UpdatePlayerScore(uName, { 'playerId': mixerMatchPlayers[2]['_id'], 'score': 9, })
    mixerGameTemp = mongo_db.find_one('mixerGame', { 'uName': uName })['item']
    submittedCount = 0
    for player in mixerGameTemp['players']:
        assert player['reward'] == ''
        if player['playerId'] == mixerMatchPlayers[2]['_id']:
            assert player['score'] == 9
            assert player['scoreState'] == 'submitted'
        if player['scoreState'] == 'submitted':
            submittedCount += 1
    assert submittedCount == 3

    ret = _mixer_game.UpdatePlayerScore(uName, { 'playerId': mixerMatchPlayers[3]['_id'], 'score': 4, })
    mixerGameTemp = mongo_db.find_one('mixerGame', { 'uName': uName })['item']
    submittedCount = 0
    for player in mixerGameTemp['players']:
        assert player['reward'] == ''
        if player['playerId'] == mixerMatchPlayers[3]['_id']:
            assert player['score'] == 4
            assert player['scoreState'] == 'submitted'
        if player['scoreState'] == 'submitted':
            submittedCount += 1
    assert submittedCount == 4

    ret = _mixer_game.UpdatePlayerScore(uName, { 'playerId': mixerMatchPlayers[4]['_id'], 'score': 6, })
    mixerGameTemp = mongo_db.find_one('mixerGame', { 'uName': uName })['item']
    submittedCount = 0
    for player in mixerGameTemp['players']:
        assert player['reward'] == ''
        if player['playerId'] == mixerMatchPlayers[4]['_id']:
            assert player['score'] == 6
            assert player['scoreState'] == 'submitted'
        if player['scoreState'] == 'submitted':
            submittedCount += 1
    assert submittedCount == 5

    ret = _mixer_game.UpdatePlayerScore(uName, { 'playerId': mixerMatchPlayers[5]['_id'], 'score': 3, })
    assert ret['removeSocketGroupName'] == 'mixerGame_' + uName
    mixerGameTemp = mongo_db.find_one('mixerGame', { 'uName': uName })['item']
    submittedCount = 0
    randomRewardCount = 0
    for player in mixerGameTemp['players']:
        if player['playerId'] == mixerMatchPlayers[2]['_id']:
            assert player['reward'] == 'winner'
        if player['reward'] == 'random':
            randomRewardCount += 1
        if player['playerId'] == mixerMatchPlayers[5]['_id']:
            assert player['score'] == 3
            assert player['scoreState'] == 'submitted'
        if player['scoreState'] == 'submitted':
            submittedCount += 1
    assert submittedCount == 6
    # assert randomRewardCount == 1
    assert randomRewardCount == 0

    # ret = _mixer_game.ClaimReward(uName, mixerMatchPlayers[2]['userId'], mixerMatchPlayers[2]['_id'])
    # assert ret['valid'] == 1
    # item = mongo_db.find_one('userCreditPayment', { 'userId': mixerMatchPlayers[2]['userId'] })['item']
    # assert item['amountUSD'] == 10
    # assert item['forType'] == 'mixerGame'
    # assert item['forId'] == mixerGame['_id']

    _mongo_mock.CleanUp()