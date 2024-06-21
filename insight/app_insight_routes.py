from common import mongo_db_crud as _mongo_db_crud
from common import socket as _socket
from insight import app_insight as _app_insight

def addRoutes():
    def Get(data, auth, websocket):
        return _app_insight.GetAppInsights()
    _socket.add_route('GetAppInsights', Get)

    def AddView(data, auth, websocket):
        return _app_insight.AddView(data['fieldKey'], userOrIP = data['userOrIP'])
    _socket.add_route('AddAppInsightView', AddView)

addRoutes()
