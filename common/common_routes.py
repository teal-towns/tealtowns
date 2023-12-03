# from fastapi import APIRouter

from common import socket as _socket

# router = APIRouter()

def addRoutes():
    def GetAllowedVersions(data, auth, websocket):
        # We must support at least 2 versions since frontend (mobile apps) will
        # not instant update in sync with breaking changes on backend. BUT to keep
        # code clean, force update for earlier versions.
        allowedVersions = ['0.0.0', '0.0.1']
        ret = { 'valid': 1, 'msg': '', 'versions': allowedVersions }
        return ret
    _socket.add_route('getAllowedVersions', GetAllowedVersions)

    def Ping(data, auth, websocket):
        ret = { 'valid': '1', 'msg': '' }
        return ret 
    _socket.add_route('ping', Ping)

addRoutes()
