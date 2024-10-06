from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
import mongo_db
import websocket_clients as _websocket_clients
from mixer import mixer_game as _mixer_game

def addRoutes():
    def GetByUName(data, auth, websocket):
        return _mongo_db_crud.GetByUName('mixerGame', data['uName'])
    _socket.add_route('GetMixerGameByUName', GetByUName)

    # def ClaimReward(data, auth, websocket):
    #     return _mixer_game.ClaimReward(data['mixerGameUName'], data['userId'], data['playerId'])
    # _socket.add_route('ClaimMixerGameReward', ClaimReward)

def addRoutesAsync():
    async def Save(data, auth, websocket):
        ret = _mixer_game.Save(data['mixerGame'])
        if ret['valid'] == 1:
            # Get mixer game (all fields), for sending to all game players.
            query = { '_id': mongo_db.to_object_id(ret['mixerGame']['_id']) }
            mixerGame = mongo_db.find_one('mixerGame', query)['item']
            uName = mixerGame['uName']
            dataSend = { 'route': 'OnMixerGame', 'auth': auth,
                'data': { 'valid': 1, 'message': '', 'mixerGame': mixerGame } }
            groupName = 'mixerGame_' + uName
            await _websocket_clients.SendToGroupsJson(dataSend, [groupName])
        # return ret
        await _socket.sendAsync(websocket, 'SaveMixerGame', ret, auth)
    _socket.add_route('SaveMixerGame', Save, 'async')

    async def UpdatePlayerScore(data, auth, websocket):
        ret = _mixer_game.UpdatePlayerScore(data['mixerGameUName'], data['player'])
        if ret['valid'] == 1:
            uName = data['mixerGameUName']
            mixerGame = None
            if 'mixerGame' in ret:
                mixerGame = ret['mixerGame']
            else:
                query = { 'uName': uName }
                # Get mixer game (all fields).
                mixerGame = mongo_db.find_one('mixerGame', query)['item']
            dataSend = { 'route': 'OnMixerGame', 'auth': auth,
                'data': { 'valid': 1, 'message': '', 'mixerGame': mixerGame } }
            groupName = 'mixerGame_' + uName
            await _websocket_clients.SendToGroupsJson(dataSend, [groupName])
            if 'mixerGame' in ret:
                del ret['mixerGame']
            if 'removeSocketGroupName' in ret:
                _websocket_clients.RemoveGroup(ret['removeSocketGroupName'])
                del ret['removeSocketGroupName']
        # return ret
        await _socket.sendAsync(websocket, 'UpdateMixerGamePlayerScore', ret, auth)
    _socket.add_route('UpdateMixerGamePlayerScore', UpdatePlayerScore, 'async')

addRoutes()
addRoutesAsync()
