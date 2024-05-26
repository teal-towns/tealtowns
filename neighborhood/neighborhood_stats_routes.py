from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from neighborhood import neighborhood_stats as _neighborhood_stats

def addRoutes():
    def ComputeNeighborhoodStats(data, auth, websocket):
        return _neighborhood_stats.ComputeNeighborhoodStats(data['uName'])
    _socket.add_route('ComputeNeighborhoodStats', ComputeNeighborhoodStats)

addRoutes()
