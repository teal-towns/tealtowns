from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
import lodash
from neighborhood import neighborhood_stats as _neighborhood_stats

def addRoutes():
    def ComputeNeighborhoodStats(data, auth, websocket):
        return _neighborhood_stats.ComputeNeighborhoodStats(data['uName'])
    _socket.add_route('ComputeNeighborhoodStats', ComputeNeighborhoodStats)

    def SearchNeighborhoodInsights(data, auth, websocket):
        data = lodash.extend_object({
            'limit': 100,
            'skip': 0,
            'sortKeys': '-usersCount',
        }, data)
        return _neighborhood_stats.SearchInsights(sortKeys = data['sortKeys'],
            limit = data['limit'], skip = data['skip'])
    _socket.add_route('SearchNeighborhoodInsights', SearchNeighborhoodInsights)

addRoutes()
