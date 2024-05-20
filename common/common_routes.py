# from fastapi import APIRouter

from common import socket as _socket
import websocket_clients as _websocket_clients

# router = APIRouter()

def addRoutes():
    def GetAllowedVersions(data, auth, websocket):
        # We must support at least 2 versions since frontend (mobile apps) will
        # not instant update in sync with breaking changes on backend. BUT to keep
        # code clean, force update for earlier versions.
        allowedVersions = ['0.0.0', '0.0.1']
        ret = { 'valid': 1, 'message': '', 'versions': allowedVersions }
        return ret
    _socket.add_route('getAllowedVersions', GetAllowedVersions)

    def Ping(data, auth, websocket):
        ret = { 'valid': '1', 'message': '' }
        return ret 
    _socket.add_route('ping', Ping)

    def AddSocketGroupUsers(data, auth, websocket):
        ret = { 'valid': '1', 'message': '' }
        _websocket_clients.AddUsersToGroup(data['groupName'], data['userIds'], ws = websocket)
        return ret
    _socket.add_route('AddSocketGroupUsers', AddSocketGroupUsers)

    def RemoveSocketGroupUsers(data, auth, websocket):
        ret = { 'valid': '1', 'message': '' }
        _websocket_clients.RemoveUsersFromGroup(data['groupName'], data['userIds'])
        return ret
    _socket.add_route('RemoveSocketGroupUsers', RemoveSocketGroupUsers)

addRoutes()
