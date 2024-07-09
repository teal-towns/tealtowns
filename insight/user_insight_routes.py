from common import socket as _socket
from insight import user_insight as _user_insight

def addRoutes():
    def SetActionAt(data, auth, websocket):
        return _user_insight.SetActionAt(data['userId'], data['field'])
    _socket.add_route('UserInsightSetActionAt', SetActionAt)

    def GetAmbassadorInsights(data, auth, websocket):
        return _user_insight.GetAmbassadorInsights()
    _socket.add_route('GetAmbassadorInsights', GetAmbassadorInsights)

addRoutes()
