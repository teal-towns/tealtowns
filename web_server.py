import os
from aiohttp import web
import aiohttp
import aiohttp_cors
import asyncio
import json
import mimetypes
import sentry_sdk
import ssl
import sys
import time
import threading
import traceback

from common import socket as _socket
import log
import ml_config
import mongo_db
import notifications
from permission import route_permissions as _route_permissions
import websocket_clients as _websocket_clients

import routes_http
# import routes_websocket

from user_auth import user_auth
from image import file_upload as _file_upload

from migration import migrations as _migrations

# AIOHTTP_NOSENDFILE=1

config = ml_config.get_config()
if 'sentry' in config and 'dsn' in config['sentry'] and \
    ('test_mode' not in config['sentry'] or not config['sentry']['test_mode']):
    sentry_sdk.init(dsn=config['sentry']['dsn'], traces_sample_rate=1.0, profiles_sample_rate=1.0,)
log.init_logger(config)
db = ml_config.get_db(config)
config_notifications = config['notifications'] or {}
notifications.set_config(config_notifications)

_migrations.RunAll()

# Import routes; this will auto add themselves
httpRoutesFunc = []
from blog import blog_routes as _blog_routes
from common import common_routes as _common_routes
from event import event_insight_routes as _event_insight_routes
from event import event_routes as _event_routes
from event import event_feedback_routes as _event_feedback_routes
from event import featured_event_photo_routes as _featured_event_photo_routes
from event import user_event_routes as _user_event_routes
from event import user_feedback_routes as _user_feedback_routes
from event import user_weekly_event_routes as _user_weekly_event_routes
from event import weekly_event_routes as _weekly_event_routes
from icebreaker import icebreaker_routes as _icebreaker_routes
from image import image_routes as _image_routes
from insight import app_insight_routes as _app_insight_routes
from insight import user_insight_routes as _user_insight_routes
from neighborhood import neighborhood_routes as _neighborhood_routes
from neighborhood import neighborhood_group_routes as _neighborhood_group_routes
from neighborhood import neighborhood_stats_routes as _neighborhood_stats_routes
from neighborhood import user_neighborhood_routes as _user_neighborhood_routes
from neighborhood import user_neighborhood_weekly_update_routes as _user_neighborhood_weekly_update_routes
from pay_mercury import pay_mercury_routes as _pay_mercury_routes
from shared_item import shared_item_routes as _shared_item_routes
from shared_item import shared_item_owner_routes as _shared_item_owner_routes
from pay_stripe import stripe_routes as _stripe_routes
httpRoutesFunc.append(_stripe_routes.Routes)
from user import user_availability_routes as _user_availability_routes
from user import user_interest_routes as _user_interest_routes
from user_auth import user_auth_routes as _user_auth_routes
from user_auth import user_routes as _user_routes
from user_follow_up import user_follow_up_routes as _user_follow_up_routes
from user_message import user_message_routes as _user_message_routes
from user_payment import user_payment_routes as _user_payment_routes
from vector_tiles import vector_tiles_routes as _vector_tiles_routes

paths_index = config['web_server']['index'] if 'index' in config['web_server'] else None
paths_static = config['web_server']['static'] if 'static' in config['web_server'] else None

log.log('warn', 'web_server starting')

from event import weekly_event as _weekly_event
thread = threading.Thread(target = _weekly_event.CheckRSVPDeadlineLoop, args=())
thread.start()
from event import event_feedback as _event_feedback
thread2 = threading.Thread(target = _event_feedback.CheckEventFeedbackLoop, args=())
thread2.start()
from neighborhood import neighborhood_stats as _neighborhood_stats
thread3 = threading.Thread(target = _neighborhood_stats.ComputeNeighborhoodStatsLoop, args=())
thread3.start()
from pay_mercury import pay_mercury as _pay_mercury
thread4 = threading.Thread(target = _pay_mercury.CheckDoTransactionsLoop, args=())
thread4.start()
from user_follow_up import user_follow_up as _user_follow_up
thread5 = threading.Thread(target = _user_follow_up.CheckDoUserFollowUpLoop, args=())
thread5.start()

# Regular websocket
async def websocket_handler(request):

    websocket = web.WebSocketResponse(max_msg_size = 100 * 1024 * 1024)
    await websocket.prepare(request)

    async for msg in websocket:
        if msg.type == aiohttp.WSMsgType.ERROR:
            print('websocket connection closed with exception %s' % websocket.exception())
        else:
            if msg.type == aiohttp.WSMsgType.TEXT:
                dataString = msg.data
            elif msg.type == aiohttp.WSMsgType.BINARY:
                dataString = msg.data.decode(encoding='utf-8')
            try:
                dataRaw = json.loads(dataString)
                auth = dataRaw["auth"] if "auth" in dataRaw else {}
                if 'userId' in auth and auth['userId'] != '':
                    _websocket_clients.AddClient(auth['userId'], websocket)
                msgId = dataRaw['data']['_msgId'] if '_msgId' in dataRaw['data'] else ''
                retData = _route_permissions.Allowed(dataRaw["route"], auth, dataRaw["data"])
                if retData['valid']:
                    route_type = _socket.get_route_type(dataRaw["route"])
                    if route_type == "async":
                        await _socket.socket_router_async(websocket, dataRaw["route"], dataRaw["data"], auth)
                    elif route_type == "sync":
                        retData = _socket.socket_router(websocket, dataRaw["route"], dataRaw["data"], auth)
                retData['_msgId'] = msgId
                ret = _socket.form_send_data(dataRaw["route"], retData, auth)
                # await websocket.send_text(json.dumps(ret))
                utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
                await websocket.send_bytes(utf8Bytes)

                # data = json.loads(dataString)

                # auth = data['auth'] if 'auth' in data else {}

                # retData = routes_websocket.routeIt(data['route'], data['data'], auth)

                # # Handle socket connections.
                # if '_socketAdd' in retData:
                #     _websocket_clients.AddClient(retData['_socketAdd']['userId'], websocket)
                #     del retData['_socketAdd']
                # if '_socketGroupAdd' in retData:
                #     _websocket_clients.AddUsersToGroup(retData['_socketGroupAdd']['group_name'],
                #         retData['_socketGroupAdd']['userIds'])
                #     del retData['_socketGroupAdd']

                # if '_socketSendSeparate' in retData:
                #     for sendInfo in retData['_socketSendSeparate']:
                #         sendTemp = { "route": sendInfo['route'],
                #             "data": sendInfo['data'],
                #             "auth": auth }
                #         utf8Bytes = json.dumps(sendTemp).encode(encoding='utf-8')
                #         if 'userIds' in sendInfo:
                #             await _websocket_clients.SendToUsers(utf8Bytes, sendInfo['userIds'])
                #         elif 'groups' in sendInfo:
                #             await _websocket_clients.SendToGroups(utf8Bytes, sendInfo['groups'])
                #     del retData['_socketSendSeparate']

                # # Must be after send, in case want to send a message before remove.
                # if '_socketRemove' in retData:
                #     _websocket_clients.RemoveClientsByUser(retData['_socketRemove']['userId'])
                #     del retData['_socketRemove']

                # # See if should send to multiple connections.
                # if '_socketSend' in retData:
                #     skipUserIds = retData['_socketSend']['skipUserIds'] if 'skipUserIds' in \
                #         retData['_socketSend'] else []
                #     if 'groups' in retData['_socketSend']:
                #         groups = retData['_socketSend']['groups']
                #         del retData['_socketSend']
                #         ret = { "route": data['route'], "data": retData, "auth": auth }
                #         utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
                #         await _websocket_clients.SendToGroups(utf8Bytes, groups, skipUserIds)
                #     elif 'users' in retData['_socketSend']:
                #         del retData['_socketSend']
                #         users = retData['_socketSend']['users']
                #         ret = { "route": data['route'], "data": retData, "auth": auth }
                #         utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
                #         await _websocket_clients.SendToUsers(utf8Bytes, users, skipUserIds)
                # elif '_socketSkip' in retData:
                #     pass
                # else:
                #     ret = { "route": data['route'], "data": retData, "auth": auth }
                #     # await websocket.send_json(ret)
                #     # utf8Bytes = bytes(json.dumps(ret), 'utf-8')
                #     utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
                #     await websocket.send_bytes(utf8Bytes)
            except Exception as e:
                print ('json parse exception', dataString, e)
                traceback.print_exc()
                log.log('warn', 'web_server json parse exception', dataString, str(e))

    _websocket_clients.RemoveClient(id(websocket))
    print('websocket connection closed')

    return websocket

async def index(request):
    """Serve the client-side application."""
    with open(paths_index['files'] + '/index.html') as f:
        return web.Response(text=f.read(), content_type='text/html')

async def static_files(request):
    # Does not actually work, but prevents error at least..
    encoding = 'latin-1' if 'favicon' in request.path else None
    contentType = mimetypes.guess_type(request.path)[0]
    # contentType = request.content_type
    path = paths_index['files'] + request.path
    if os.path.exists(path):
        with open((path), encoding=encoding) as f:
            try:
                return web.Response(text=f.read(), content_type=contentType)
            except Exception as e:
                print ('static_files read exception', path, encoding, e)
                with open(paths_index['files'] + '/index.html') as f:
                    return web.Response(text=f.read(), content_type='text/html')
    else:
        print ('static_files path does not exist', path)
        with open(paths_index['files'] + '/index.html') as f:
            return web.Response(text=f.read(), content_type='text/html')

async def start_async_app():
    try:
        # App 1 - main
        app = web.Application()
        app.add_routes([web.get('/ws', websocket_handler)])

        # Add CORS: https://docs.aiohttp.org/en/stable/web_advanced.html#cors-support
        corsUrls = config['web_server']['cors_urls']
        defaults = {}
        for url in corsUrls:
            if url == 'WILDCARD':
                defaults['*'] = aiohttp_cors.ResourceOptions(allow_credentials=True, expose_headers="*", allow_headers="*")
            else:
                defaults[url] = aiohttp_cors.ResourceOptions(allow_credentials=True, expose_headers="*", allow_headers="*")
        cors = aiohttp_cors.setup(app, defaults = defaults)

        # To enable CORS processing for specific route you need to add
        # that route to the CORS configuration object and specify its
        # CORS options.
        routes_http.Routes(app, cors)
        for httpRouteFunc in httpRoutesFunc:
            httpRouteFunc(app, cors)

        if paths_index is not None and paths_static is not None:
            # app.router.add_static(paths_static['route'], paths_static['files'])

            # Not able to match whole folder?
            static_files_list = ['flutter_service_worker.js', 'favicon.ico']
            files = os.listdir(paths_static['files'])
            for file in files:
                if file != 'index.html':
                    static_files_list.append(file)
            for file in static_files_list:
                if os.path.isdir(paths_static['files'] + '/' + file):
                    app.router.add_get(paths_index['route'] + file, static_files)
                    app.add_routes([web.static(paths_static['route'] + '/' + file, paths_static['files'] + '/' + file)])
                else:
                    app.router.add_get(paths_index['route'] + file, static_files)

            app.add_routes([web.static('/assets', paths_static['files'] + '/assets')])
            # app.add_routes([web.static('/static/css', paths_static['files'] + '/css')])

        # Need to create uploads folder here so it exists.
        _file_upload.CreateUploadsDirs()
        if 'static_folders' in config['web_server']:
            for path1 in config['web_server']['static_folders']:
                if not os.path.isdir(path1):
                    os.mkdir(path1)
                # defaults[url] = aiohttp_cors.ResourceOptions()
                app.add_routes([web.static('/' + path1 + '/', path1)])
                app.add_routes([web.static('/' + path1, path1)])

        # Ensure have CORS for all routes
        for route in list(app.router.routes()):
            try:
                cors.add(route)
            except:
                pass

        # https://stackoverflow.com/questions/34565705/asyncio-and-aiohttp-route-all-urls-paths-to-handler
        app.router.add_get('/{tail:.*}', index)

        if config['web_server']['ssl'] and config['web_server']['ssl']['enabled']:
            sslInfo = config['web_server']['ssl']
            sslContext = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
            sslContext.load_cert_chain(sslInfo['cert_path'], sslInfo['key_path'])
            portToUse = sslInfo['port']
        else:
            portToUse = config['web_server']['port']
            sslContext = None
        # web.run_app(app, port=portToUse, ssl_context=sslContext)

        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, port=portToUse, ssl_context=sslContext)
        await site.start()
        print('App1 started on port', portToUse)
        # Site 2
        if config['web_server']['port_redirect']:
            site2 = web.TCPSite(runner, port=config['web_server']['port_redirect'])
            await site2.start()
            print('App2 started on port', config['web_server']['port_redirect'])
        # wait for finish signal
        # await runner.cleanup()
        return runner, site

    except Exception as e:
        sys.stderr.write('Error: ' + format(str(e)) + "\n")
        sys.exit(1)

if __name__ == '__main__':
    loop = asyncio.get_event_loop()
    runner, site = loop.run_until_complete(start_async_app())
    try:
        loop.run_forever()
    except KeyboardInterrupt as err:
        loop.run_until_complete(runner.cleanup())
