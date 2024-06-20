from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
import mongo_db

def addRoutes():
    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'icebreaker': '',
            'limit': 25,
            'skip': 0,
        }, data)
        return _mongo_db_crud.Search('icebreaker', stringKeyVals = { 'icebreaker': data['icebreaker'], },
            limit = data['limit'], skip = data['skip'])
    _socket.add_route('SearchIcebreakers', Search)

    def Save(data, auth, websocket):
        return _mongo_db_crud.Save('icebreaker', data['icebreaker'])
    _socket.add_route('SaveIcebreaker', Save)

    def Remove(data, auth, websocket):
        return _mongo_db_crud.RemoveById('icebreaker', data['id'])
    _socket.add_route('RemoveIcebreaker', Remove)

    def GetById(data, auth, websocket):
        return _mongo_db_crud.GetById('icebreaker', data['id'])
    _socket.add_route('GetIcebreakerById', GetById)

    def GetRandom(data, auth, websocket):
        ret1 = mongo_db.FindRandom('icebreaker', data['count'])
        return {
            'valid': 1,
            'message': '',
            'icebreakers': ret1['items'],
        }
    _socket.add_route('GetRandomIcebreakers', GetRandom)

addRoutes()
