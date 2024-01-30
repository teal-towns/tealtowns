from aiohttp import web
import os

import ci_webhook
from user_auth import user_auth
from image import file_upload as _file_upload
import ml_config

config = ml_config.get_config()

def Routes(app, cors):
    resource = cors.add(app.router.add_resource('/web/ci-webhook'))
    cors.add(resource.add_route('POST', CIWebhook))
    resource = cors.add(app.router.add_resource('/web/ci-webhook-get'))
    cors.add(resource.add_route('GET', CIWebhookTesting))

    resource = cors.add(app.router.add_resource('/web/getUserSession'))
    cors.add(resource.add_route("POST", GetUserSession))

    resource = cors.add(app.router.add_resource('/web/fileUpload'))
    cors.add(resource.add_route("POST", fileUpload))

def CIWebhookTesting(request):
    data = request.query
    ci_webhook.Restart(0)
    return web.json_response({'valid': 1, 'message': 'CIWebhookTesting 2'})

async def CIWebhook(request):
    data = await request.json()
    ci_webhook.Restart(1)
    return web.json_response({'valid': 1, 'message': 'CIWebhook'})

async def GetUserSession(request):
    data = await request.json()
    ret = user_auth.getSession(data['userId'], data['sessionId'])
    if ret['valid']:
        # Join (to string) any nested fields for C# typings..
        if 'roles' in ret['user']:
            ret['user']['roles'] = ",".join(ret['user']['roles'])
        ret['_socketAdd'] = { 'userId': ret['user']['_id'] }

    return web.json_response(ret)

async def fileUpload(request):
    # Read file in parts and save locally in temp folder.
    # https://docs.aiohttp.org/en/stable/web_quickstart.html#file-uploads
    reader = await request.multipart()
    # reader.next() will `yield` the fields of your form
    # Order matters - mime must be sent BEFORE file.
    field = await reader.next()
    assert field.name == 'mime'
    mime = await field.text()
    field = await reader.next()
    assert field.name == 'keyType'
    keyType = await field.text()
    field = await reader.next()
    assert field.name == 'file'
    file = await field.read(decode=False)
    # filename = field.filename
    filename = _file_upload.FormFilename(mime)
    # You cannot rely on Content-Length if transfer is chunked.
    size = 0
    _file_upload.CreateUploadsDirs()
    filePath = os.path.join('uploads/temp/', filename)
    with open(filePath, 'wb') as f:
        # while True:
        #     chunk = await file.read_chunk()  # 8192 bytes by default.
        #     if not chunk:
        #         break
        #     size += len(chunk)
        #     f.write(chunk)
        # We are already sending back a blob / bytearray so just write it directly.
        f.write(file)

    # data = request.post()
    # ret = _file_upload.Upload(data['file'])
    if keyType == 'imageUpload':
        ret = _file_upload.HandleImage(
            filePath, config['web_server']['urls']['base_server'], filename)
    # Remove temp file.
    os.remove(filePath)
    return web.json_response(ret)

async def SaveImageData(request):
    data = await request.json()
    fileName = data['fileName']
    fileData = data['fileData']
    maxSize = data['maxSize']
    ret = _file_upload.SaveImageData(
        fileData, config['web_server']['urls']['base_server'], filename=fileName, maxSize=maxSize)
    return web.json_response(ret)

async def SaveFileData(request):
    data = await request.json()
    fileName = data['fileName']
    fileData = data['fileData']
    ret = _file_upload.SaveFileData(
        fileData, config['web_server']['urls']['base_server'], filename=fileName)
    return web.json_response(ret)
