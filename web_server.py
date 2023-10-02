import os
from aiohttp import web
import aiohttp
import aiohttp_cors
import asyncio
import json
import mimetypes
import ssl
import sys
import time
import threading
import traceback

import log
import ml_config
import mongo_db
import notifications
import websocket_clients as _websocket_clients

import routes_http
import routes_websocket

import user_auth
from image import file_upload as _file_upload

from migration import migrations as _migrations

# AIOHTTP_NOSENDFILE=1

config = ml_config.get_config()
log.init_logger(config)
db = ml_config.get_db(config)
config_notifications = config['notifications'] or {}
notifications.set_config(config_notifications)

_migrations.RunAll()

paths_index = config['web_server']['index'] if 'index' in config['web_server'] else None
paths_static = config['web_server']['static'] if 'static' in config['web_server'] else None

log.log('warn', 'web_server starting')

# Regular websocket
async def websocket_handler(request):

    # print ('websocket_handler', request)
    ws = web.WebSocketResponse(max_msg_size = 25 * 1024 * 1024)
    await ws.prepare(request)

    async for msg in ws:
        # print ('msg', msg, ws)
        if msg.type == aiohttp.WSMsgType.ERROR:
            print('ws connection closed with exception %s' % ws.exception())
        else:
            if msg.type == aiohttp.WSMsgType.TEXT:
                dataString = msg.data
            elif msg.type == aiohttp.WSMsgType.BINARY:
                dataString = msg.data.decode(encoding='utf-8')
            # print ('dataString', dataString)
            try:
                data = json.loads(dataString)

                auth = data['auth'] if 'auth' in data else {}

                # if msg.data == 'close':
                #     await ws.close()
                # else:
                #     await ws.send_str(msg.data + '/answer')

                # if data['route'] == 'route1':
                #     ret = { "route": data['route'], "data": data['data'], "auth": auth }
                #     await ws.send_json(ret)
                # elif data['route'] == 'route2':
                #     ret = { "route": data['route'], "data": data['data'], "auth": auth }
                #     await ws.send_json(ret)

                retData = routes_websocket.routeIt(data['route'], data['data'], auth)

                # Handle socket connections.
                if '_socketAdd' in retData:
                    _websocket_clients.AddClient(retData['_socketAdd']['userId'], ws)
                    del retData['_socketAdd']
                if '_socketGroupAdd' in retData:
                    _websocket_clients.AddUsersToGroup(retData['_socketGroupAdd']['group_name'],
                        retData['_socketGroupAdd']['userIds'])
                    del retData['_socketGroupAdd']

                if '_socketSendSeparate' in retData:
                    for sendInfo in retData['_socketSendSeparate']:
                        sendTemp = { "route": sendInfo['route'],
                            "data": sendInfo['data'],
                            "auth": auth }
                        utf8Bytes = json.dumps(sendTemp).encode(encoding='utf-8')
                        if 'userIds' in sendInfo:
                            await _websocket_clients.SendToUsers(utf8Bytes, sendInfo['userIds'])
                        elif 'groups' in sendInfo:
                            await _websocket_clients.SendToGroups(utf8Bytes, sendInfo['groups'])
                    del retData['_socketSendSeparate']

                # Must be after send, in case want to send a message before remove.
                if '_socketRemove' in retData:
                    _websocket_clients.RemoveClientsByUser(retData['_socketRemove']['userId'])
                    del retData['_socketRemove']

                # See if should send to multiple connections.
                if '_socketSend' in retData:
                    skipUserIds = retData['_socketSend']['skipUserIds'] if 'skipUserIds' in \
                        retData['_socketSend'] else []
                    if 'groups' in retData['_socketSend']:
                        groups = retData['_socketSend']['groups']
                        del retData['_socketSend']
                        ret = { "route": data['route'], "data": retData, "auth": auth }
                        utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
                        await _websocket_clients.SendToGroups(utf8Bytes, groups, skipUserIds)
                    elif 'users' in retData['_socketSend']:
                        del retData['_socketSend']
                        users = retData['_socketSend']['users']
                        ret = { "route": data['route'], "data": retData, "auth": auth }
                        utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
                        await _websocket_clients.SendToUsers(utf8Bytes, users, skipUserIds)
                elif '_socketSkip' in retData:
                    pass
                else:
                    ret = { "route": data['route'], "data": retData, "auth": auth }
                    # await ws.send_json(ret)
                    # utf8Bytes = bytes(json.dumps(ret), 'utf-8')
                    utf8Bytes = json.dumps(ret).encode(encoding='utf-8')
                    await ws.send_bytes(utf8Bytes)
            except Exception as e:
                print ('json parse exception', dataString, e)
                traceback.print_exc()
                log.log('warn', 'web_server json parse exception', dataString, str(e))

    _websocket_clients.RemoveClient(id(ws))
    print('websocket connection closed')

    return ws

async def index(request):
    print ('index', request)
    """Serve the client-side application."""
    with open(paths_index['files'] + '/index.html') as f:
        return web.Response(text=f.read(), content_type='text/html')

async def static_files(request):
    print ('static_files', request)
    # Does not actually work, but prevents error at least..
    encoding = 'latin-1' if 'favicon' in request.path else None
    contentType = mimetypes.guess_type(request.path)[0]
    # contentType = request.content_type
    path = paths_index['files'] + request.path
    if os.path.exists(path):
        with open((path), encoding=encoding) as f:
            return web.Response(text=f.read(), content_type=contentType)
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
        defaults = {};
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
                    # print ('static files list', paths_index['route'] + file, static_files)
                    app.router.add_get(paths_index['route'] + file, static_files)
                    app.add_routes([web.static(paths_static['route'] + '/' + file, paths_static['files'] + '/' + file)])
                else:
                    # print ('static FILE', paths_index['route'] + file, static_files)
                    app.router.add_get(paths_index['route'] + file, static_files)

            app.add_routes([web.static('/assets', paths_static['files'] + '/assets')])
            # app.add_routes([web.static('/static/css', paths_static['files'] + '/css')])

        # Need to create uploads folder here so it exists.
        _file_upload.CreateUploadsDirs()
        if 'static_folders' in config['web_server']:
            for path1 in config['web_server']['static_folders']:
                if not os.path.isdir(path1):
                    os.mkdir(path1)
                defaults[url] = aiohttp_cors.ResourceOptions()
                app.add_routes([web.static('/' + path1 + '/', path1)])
                app.add_routes([web.static('/' + path1, path1)])
                # app.router.add_static('/' + path1 + '/', path1)

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
