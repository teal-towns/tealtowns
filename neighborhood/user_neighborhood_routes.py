from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from neighborhood import user_neighborhood as _user_neighborhood

def addRoutes():

    def Save(data, auth, websocket):
        return _user_neighborhood.Save(data['userNeighborhood'])
    _socket.add_route('SaveUserNeighborhood', Save)

    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'userId': '',
            'neighborhoodUName': '',
            'neighborhoodUNames': [],
            'roles': '', 
            'status': '',
            'limit': 25,
            'skip': 0,
            'withNeighborhoods': 0,
            'withUsers': 0,
        }, data)
        stringKeyVals = { 'userId': data['userId'], 'neighborhoodUName': data['neighborhoodUName'],
            'status': data['status'], 'roles': data['roles'], }
        listKeyVals = { 'neighborhoodUName': data['neighborhoodUNames'], }
        return _user_neighborhood.Search(stringKeyVals = stringKeyVals, listKeyVals = listKeyVals,
            limit = data['limit'], skip = data['skip'],
            withNeighborhoods = data['withNeighborhoods'], withUsers = data['withUsers'])
    _socket.add_route('SearchUserNeighborhoods', Search)

    def GetById(data, auth, websocket):
        return _mongo_db_crud.GetById('userNeighborhood', data['id'])
    _socket.add_route('GetUserNeighborhoodById', GetById)

    def RemoveRole(data, auth, websocket):
        return _user_neighborhood.RemoveRole(data['username'], data['neighborhoodUName'], data['role'])
    _socket.add_route('RemoveUserNeighborhoodRole', RemoveRole)

    def Remove(data, auth, websocket):
        return _user_neighborhood.Remove(data['username'], data['neighborhoodUName'])
    _socket.add_route('RemoveUserNeighborhood', Remove)

addRoutes()
