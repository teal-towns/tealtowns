from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from neighborhood import neighborhood_group as _neighborhood_group

def AddRoutes():
    def GetByUName(data, auth, websocket):
        return _mongo_db_crud.GetById('neighborhoodGroup', '', uName = data['uName'])
    _socket.add_route('GetNeighborhoodGroupByUName', GetByUName)

    def Save(data, auth, websocket):
        if 'neighborhoodUNames' not in data['neighborhoodGroup'] and '_id' not in data['neighborhoodGroup']:
            data['neighborhoodGroup']['neighborhoodUNames'] = []
        return _mongo_db_crud.Save('neighborhoodGroup', data['neighborhoodGroup'])
    _socket.add_route('SaveNeighborhoodGroup', Save)

    def AddNeighborhood(data, auth, websocket):
        return _neighborhood_group.AddNeighborhood(data['uName'], data['neighborhoodUName'])
    _socket.add_route('AddNeighborhoodToNeighborhoodGroup', AddNeighborhood)

    def RemoveNeighborhoods(data, auth, websocket):
        return _neighborhood_group.RemoveNeighborhoods(data['uName'], data['neighborhoodUNames'])
    _socket.add_route('RemoveNeighborhoodsFromNeighborhoodGroup', RemoveNeighborhoods)

def AddRoutesAsync():
    async def ComputeStats(data, auth, websocket):
        async def OnUpdate(data):
            await _socket.sendAsync(websocket, "ComputeNeighborhoodGroupStats", data, auth)

        return await _neighborhood_group.ComputeStats(data['uName'], onUpdate = OnUpdate)
    _socket.add_route('ComputeNeighborhoodGroupStats', ComputeStats, 'async')

AddRoutes()
AddRoutesAsync()
