import re

from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from user_message import user_message as _user_message

def addRoutes():
    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'userId': '',
            'forType': '',
            'forId': '',
            'type': '',
            'typeId': '',
            'limit': 25,
            'skip': 0,
            'sortKeys': '-updatedAt',
            'withUsers': 0,
            'withForIds': 0,
        }, data)
        stringKeyVals = { 'userId': data['userId'], 'forType': data['forType'], 'forId': data['forId'],
            'type': data['type'], 'typeId': data['typeId'], }
        return _user_message.Search(stringKeyVals, data['limit'], data['skip'], data['sortKeys'],
            withUsers = data['withUsers'], withForIds = data['withForIds'])
    _socket.add_route('SearchUserMessages', Search)

    def Save(data, auth, websocket):
        return _user_message.Save(data['userMessage'])
    _socket.add_route('SaveUserMessage', Save)

    def Remove(data, auth, websocket):
        return _mongo_db_crud.RemoveById('userMessage', data['id'])
    _socket.add_route('RemoveUserMessage', Remove)

    def GetById(data, auth, websocket):
        data = lodash.extend_object({
            'withUser': 0,
            'withForId': 0,
            'withLikeUsers': 0,
            'withSubMessages': 0,
        }, data)
        return _user_message.GetById(data['id'], data['withUser'], data['withForId'],
            data['withLikeUsers'], data['withSubMessages'])
    _socket.add_route('GetUserMessageById', GetById)

addRoutes()
