from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import websocket_clients as _websocket_clients
import mongo_db
from mixer import mixer_game as _mixer_game
from mixer import mixer_match_player as _mixer_match_player

def addRoutesAsync():
    async def Save(data, auth, websocket):
        ret = _mixer_match_player.Save(data['mixerMatchPlayer'], websocket = websocket)
        if ret['valid'] == 1 and 'mixerMatchPlayers' in ret:
            dataSend = { 'route': 'OnMixerMatchPlayers', 'auth': auth,
                'data': { 'valid': 1, 'message': '', 'mixerMatchPlayers': ret['mixerMatchPlayers'] } }
            groupName = 'mixerGame_' + ret['mixerMatchPlayer']['mixerGameUName']
            await _websocket_clients.SendToGroupsJson(dataSend, [groupName])
            del ret['mixerMatchPlayers']
        # return ret
        await _socket.sendAsync(websocket, 'SaveMixerMatchPlayer', ret, auth)
    _socket.add_route('SaveMixerMatchPlayer', Save, 'async')

    async def GetByUserId(data, auth, websocket):
        if 'userId' not in data or 'userId' == '' or 'mixerGameUName' not in data or 'mixerGameUName' == '':
            ret = { 'valid': 0, 'message': 'Missing userId or mixerGameUName' }
            # return ret
            await _socket.sendAsync(websocket, 'GetMixerMatchPlayerByUserId', ret, auth)
        else:
            stringKeyVals = { 'userId': data['userId'], 'mixerGameUName': data['mixerGameUName'] }
            ret = _mongo_db_crud.Get('mixerMatchPlayer', stringKeyVals)
            if ret['valid'] == 1 and 'mixerMatchPlayer' in ret and '_id' in ret['mixerMatchPlayer']:
                ret = _mixer_match_player.GetPlayersAndAddToSocket(ret, ret['mixerMatchPlayer'], websocket = websocket)
            if ret['valid'] == 1 and 'mixerMatchPlayers' in ret:
                dataSend = { 'route': 'OnMixerMatchPlayers', 'auth': auth,
                    'data': { 'valid': 1, 'message': '', 'mixerMatchPlayers': ret['mixerMatchPlayers'] } }
                groupName = 'mixerGame_' + ret['mixerMatchPlayer']['mixerGameUName']
                await _websocket_clients.SendToGroupsJson(dataSend, [groupName])
                del ret['mixerMatchPlayers']
            # return ret
            await _socket.sendAsync(websocket, 'SaveMixerMatchPlayer', ret, auth)
    _socket.add_route('GetMixerMatchPlayerByUserId', GetByUserId, 'async')

# addRoutes()
addRoutesAsync()
