# TODO - FastAPI (sockets at least) does not fire every other one from Unreal.
# import os
# import json

# from fastapi import FastAPI, WebSocket, WebSocketDisconnect
# from fastapi.middleware.cors import CORSMiddleware
# from fastapi.requests import Request
# from fastapi.responses import FileResponse
# from fastapi.staticfiles import StaticFiles
# from fastapi.templating import Jinja2Templates

# from common import socket as _socket
# from image import file_upload as _file_upload
# import log
# import ml_config
# import notifications
# from permission import route_permissions as _route_permissions

# from migration import migrations as _migrations

# config = ml_config.get_config()
# log.init_logger(config)
# db = ml_config.get_db(config)
# config_notifications = config['notifications'] or {}
# notifications.set_config(config_notifications)

# _migrations.RunAll()

# from blog import blog_routes as _blog_routes
# from common import common_routes as _common_routes
# from image import image_routes as _image_routes
# from user_auth import user_auth_routes as _user_auth_routes
# from vector_tiles import vector_tiles_routes as _vector_tiles_routes

# app = FastAPI()

# origins = config['web_server']['cors_urls']
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=origins,
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# app.include_router(_blog_routes.router)
# app.include_router(_common_routes.router)
# app.include_router(_image_routes.router)
# app.include_router(_user_auth_routes.router)
# app.include_router(_vector_tiles_routes.router)

# @app.websocket("/ws")
# async def websocket_endpoint(websocket: WebSocket):
#     await websocket.accept()
#     try:
#         while True:
#             try:
#                 dataString = await websocket.receive_bytes()
#                 dataString = dataString.decode(encoding='utf-8')
#             except Exception as e:
#                 dataString = await websocket.receive_text()
#             dataRaw = json.loads(dataString)
#             auth = dataRaw["auth"] if "auth" in dataRaw else {}
#             msgId = dataRaw['data']['_msgId'] if '_msgId' in dataRaw['data'] else ''
#             retData = _route_permissions.Allowed(dataRaw["route"], auth, dataRaw["data"])
#             if retData['valid']:
#                 route_type = _socket.get_route_type(dataRaw["route"])
#                 if route_type == "async":
#                     await _socket.socket_router_async(websocket, dataRaw["route"], dataRaw["data"], auth)
#                 elif route_type == "sync":
#                     retData = _socket.socket_router(websocket, dataRaw["route"], dataRaw["data"], auth)
#             retData['_msgId'] = msgId
#             ret = _socket.form_send_data(dataRaw["route"], retData, auth)
#             # await websocket.send_text(json.dumps(ret))
#             utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
#             await websocket.send_bytes(utf8Bytes)
#     except WebSocketDisconnect:
#         pass

# staticFiles = []
# if 'static' in config['web_server'] and os.path.isdir(config['web_server']['static']['files']):
#     # app.mount(config['web_server']['static']['route'],
#     # # app.mount('/',
#     #     StaticFiles(directory=config['web_server']['static']['files']), name='static')
#     pathStatic = config['web_server']['static']
#     for file in os.listdir(pathStatic['files']):
#         if os.path.isdir(pathStatic['files'] + '/' + file):
#             app.mount('/' + file, StaticFiles(directory=pathStatic['files'] + '/' + file))
#             # print ('dir', '/' + file, pathStatic['files'] + '/' + file)
#         else:
#             staticFiles.append('/' +file)
#         #     print ('file', '/' + file, pathStatic['files'] + '/' + file)
#         #     @app.get('/' + file)
#         #     def get_static_file():
#         #         return FileResponse(pathStatic['files'] + '/' + file)

# _file_upload.CreateUploadsDirs()
# if 'static_folders' in config['web_server']:
#     for path1 in config['web_server']['static_folders']:
#         if not os.path.isdir(path1):
#             os.mkdir(path1)
#         app.mount('/' + path1, StaticFiles(directory=path1), name=path1)

# templates = Jinja2Templates(directory=config['web_server']['index']['files'])
# @app.get("/{rest_of_path:path}")
# async def frontend_app(req: Request):
#     if req['path'] in staticFiles:
#         return FileResponse(config['web_server']['static']['files'] + '/' + req['path'])
#     return templates.TemplateResponse("index.html", {"request": req})
