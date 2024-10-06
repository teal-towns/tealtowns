from common import mongo_db_crud as _mongo_db_crud
from mixer import mixer_game as _mixer_game
import mongo_db
import websocket_clients as _websocket_clients

def Save(mixerMatchPlayer: dict, getAllPlayers: int = 1, addPlayerToSocketGroup: int = 1,
    websocket = None):
    # See if user already exists.
    if 'userId' in mixerMatchPlayer and len(mixerMatchPlayer['userId']) > 0:
        query = { 'mixerGameUName': mixerMatchPlayer['mixerGameUName'], 'userId': mixerMatchPlayer['userId'] }
        item = mongo_db.find_one('mixerMatchPlayer', query)['item']
        if item is not None:
            mixerMatchPlayer['_id'] = item['_id']
    ret = _mongo_db_crud.Save('mixerMatchPlayer', mixerMatchPlayer)

    if ret['valid'] == 1 and addPlayerToSocketGroup and websocket is not None:
        ret = GetPlayersAndAddToSocket(ret, mixerMatchPlayer, getAllPlayers, addPlayerToSocketGroup, websocket)

    return ret

def GetPlayersAndAddToSocket(ret: dict, mixerMatchPlayer: dict, getAllPlayers: int = 1,
    addPlayerToSocketGroup: int = 1, websocket = None):
    userId = mixerMatchPlayer['userId'] if 'userId' in mixerMatchPlayer else ''
    if ret['valid'] == 1 and addPlayerToSocketGroup and websocket is not None:
        groupName = 'mixerGame_' + mixerMatchPlayer['mixerGameUName']
        generateUserId = 1
        userIds = []
        if len(userId) > 0:
            generateUserId = 0
            userIds = [ userId ]
        _websocket_clients.AddUsersToGroup(groupName, userIds, ws = websocket,
            generateUserId = generateUserId)
        ret['socketGroupName'] = groupName

    if ret['valid'] == 1 and getAllPlayers:
        # if 'insert' in ret and ret['insert']:
        if True:
            # Add player to game score (with 0 score to start).
            player = {
                'playerId': ret['mixerMatchPlayer']['_id'],
                'playerName': mixerMatchPlayer['name'],
                'userId': userId,
                'score': 0,
                'scoreState': 'waiting',
                'reward': '',
            }
            _mixer_game.AddPlayer(mixerMatchPlayer['mixerGameUName'], player)
        # Get all players (for sending to all game players).
        query = { 'mixerGameUName': ret['mixerMatchPlayer']['mixerGameUName'] }
        ret['mixerMatchPlayers'] = mongo_db.find('mixerMatchPlayer', query, sort_obj = { 'name': 1 })['items']

    return ret
