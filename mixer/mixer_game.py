import random

from common import mongo_db_crud as _mongo_db_crud
import lodash
import mongo_db
from user_payment import user_payment as _user_payment

def Save(mixerGame: dict):
    mixerGame = _mongo_db_crud.CleanId(mixerGame)
    if '_id' not in mixerGame:
        mixerGame['uName'] = lodash.CreateUName('')
        mixerGame = lodash.extend_object({
            'players': [],
            'state': 'playing',
            'gameDetails': {},
        }, mixerGame)
    return _mongo_db_crud.Save('mixerGame', mixerGame)

def AddPlayer(mixerGameUName: str, player: dict):
    ret = { 'valid': 0, 'message': '', }
    # Check if already exists; only add if not.
    query = { 'uName': mixerGameUName, 'players': { '$elemMatch': { 'playerId': player['playerId'] }} }
    mixerGame = mongo_db.find_one('mixerGame', query)['item']
    if mixerGame is None:
        query = { 'uName': mixerGameUName }
        player = lodash.extend_object({
            'score': 0,
            'scoreState': 'waiting',
            'reward': '',
            'userId': '',
        }, player)
        mutation = { '$push': { 'players': player } }
        ret = mongo_db.update_one('mixerGame', query, mutation)
    return ret

def UpdatePlayerScore(mixerGameUName: str, player: dict, giveRandomReward: int = 0):
    query = { 'uName': mixerGameUName, 'players': { '$elemMatch': { 'playerId': player['playerId'] }} }
    mutation = { '$set': { 'players.$.score': player['score'], 'players.$.scoreState': 'submitted' } }
    ret = mongo_db.update_one('mixerGame', query, mutation, validate = 0)

    # Check if all players have submitted scores, in which case sort by scores, reward the winner and a random player.
    query = { 'uName': mixerGameUName }
    # Get mixer game (all fields).
    mixerGame = mongo_db.find_one('mixerGame', query)['item']
    # Sort first so can store indices for non signed up players to select from there as preference.
    players = lodash.sort2D(mixerGame['players'], 'score', 'descending')
    submittedCount = 0
    indicesNotSignedUp = []
    for index, player in enumerate(players):
        # Unset any rewards (since players can submit more than once)
        players[index]['reward'] = ''
        if player['scoreState'] == 'submitted':
            submittedCount += 1
        # Skip first index, as that will be winner.
        if len(player['userId']) < 1 and index > 0:
            indicesNotSignedUp.append(index)
    if submittedCount == len(mixerGame['players']):
        players[0]['reward'] = 'winner'
        if len(players) > 1 and giveRandomReward:
            # Start at 1 to skip winner.
            if len(indicesNotSignedUp) > 0:
                index = random.choice(indicesNotSignedUp)
            else:
                index = random.randint(1, (len(players) - 1))
            players[index]['reward'] = 'random'
        query = { 'uName': mixerGameUName }
        mutation = { '$set': { 'players': players } }
        mongo_db.update_one('mixerGame', query, mutation)
        mixerGame['players'] = players
        if mixerGame['state'] == 'gameOver':
            ret['removeSocketGroupName'] = 'mixerGame_' + mixerGameUName

    ret['mixerGame'] = mixerGame
    return ret

# def ClaimReward(mixerGameUName: str, userId: str, playerId: str):
#     mixerGame = mongo_db.find_one('mixerGame', { 'uName': mixerGameUName })['item']
#     ret = _user_payment.AddCreditPayment(userId, 10, 'mixerGame', mixerGame['_id'])
#     # Update user id for player.
#     query = { 'mixerGameUName': mixerGameUName, '_id': mongo_db.to_object_id(playerId) }
#     mutation = { '$set': { 'userId': userId } }
#     mongo_db.update_one('mixerMatchPlayer', query, mutation)
#     return ret
