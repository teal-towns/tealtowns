import re

from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from neighborhood import neighborhood as _neighborhood

def addRoutes():
    def Search(data, auth, websocket):
        data = lodash.extend_object({
            'title': '',
            'location': {},
            'withLocationDistance': 0,
            'limit': 25,
            'skip': 0,
            'userId': '',
        }, data)
        return _neighborhood.SearchNear(stringKeyVals = { 'title': data['title'], },
            locationKeyVals = { 'location': data['location'], }, limit = data['limit'], skip = data['skip'],
            withLocationDistance = data['withLocationDistance'],
            userId = data['userId'])
    _socket.add_route('SearchNeighborhoods', Search)

    def Save(data, auth, websocket):
        regex = re.compile('[^a-zA-Z0-9]')
        data['neighborhood']['uName'] = regex.sub('', data['neighborhood']['uName'].lower())
        return _mongo_db_crud.Save('neighborhood', data['neighborhood'])
    _socket.add_route('SaveNeighborhood', Save)

    def Remove(data, auth, websocket):
        return _mongo_db_crud.RemoveById('neighborhood', data['id'])
    _socket.add_route('RemoveNeighborhood', Remove)

    def GetByUName(data, auth, websocket):
        data = lodash.extend_object({
            'withWeeklyEvents': 0,
            'withSharedItems': 0,
            'weeklyEventsCount': 3,
            'sharedItemsCount': 3,
            'limitCount': 250,
            'withUsersCount': 0,
            'withUniqueEventUsersCount': 0,
            'userId': '',
        }, data)
        return _neighborhood.GetByUName(data['uName'], data['withWeeklyEvents'], data['withSharedItems'],
            data['weeklyEventsCount'],
            data['sharedItemsCount'], limitCount = data['limitCount'], withUsersCount = data['withUsersCount'],
            withUniqueEventUsersCount = data['withUniqueEventUsersCount'], userId = data['userId'])
    _socket.add_route('GetNeighborhoodByUName', GetByUName)

addRoutes()
