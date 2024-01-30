# from fastapi import APIRouter

from common import route_parse as _route_parse
from common import socket as _socket
from image import file_upload as _file_upload
from image import image as _image

import ml_config
config = ml_config.get_config()

# router = APIRouter()

def addRoutes():
    def GetImageData(data, auth, websocket):
        imageDataString = _file_upload.GetImageData(data['image_url'])
        ret = { 'valid': '1', 'message': '', 'image_url': data['image_url'],
            'image_data': imageDataString }
        return ret
    _socket.add_route('getImageData', GetImageData)

    def GetImages(data, auth, websocket):
        title = data['title'] if 'title' in data else ''
        url = data['url'] if 'url' in data else ''
        userIdCreator = data['userIdCreator'] if 'userIdCreator' in data else ''
        ret = _image.Get(title, url, userIdCreator, data['limit'], data['skip'])
        ret = _route_parse.formatRet(data, ret)
        return ret
    _socket.add_route('getImages', GetImages)

    def SaveFileData(data, auth, websocket):
        if data['fileType'] == 'image':
            saveToUserImages = data['saveToUserImages'] if 'saveToUserImages' in data else False
            maxSize = data['maxSize'] if 'maxSize' in data else 600
            ret = _file_upload.SaveImageData(data['fileData'], config['web_server']['urls']['base_server'],
                maxSize = maxSize, removeOriginalFile = 1)
            if ret['valid'] and saveToUserImages and len(auth['userId']) > 0:
                title = data['title'] if 'title' in data else ''
                if len(title) > 0:
                    userImage = { 'url': ret['url'], 'title': title, 'userIdCreator': auth['userId'] }
                    retUserImage = _image.Save(userImage)
                    ret['userImage'] = _route_parse.formatRet(data, retUserImage)
        # TODO
        # elif 'routeKey' in data and data['routeKey'] == 'polygonUpload':
        #     ret = _upload_coordinates.UploadFileDataToBucket(data['fileData'], fileType = data['fileType'],
        #         fileName = data['fileName'], title = data['title'])
        # elif 'routeKey' in data and data['routeKey'] == 'polygonUploadToTiles':
        #     ret = _upload_coordinates.UploadFileDataToBucket(data['fileData'], fileType = data['fileType'],
        #         fileName = data['fileName'], title = data['title'])
        #     retPolygon = _vector_tiles_polygon.GetPolygonFileTilesInfo(ret['fileUrl'])
        #     for key in retPolygon:
        #         ret[key] = retPolygon[key]
        else:
            ret = _file_upload.SaveFileData(data['fileData'], config['web_server']['urls']['base_server'], data['fileName'])
        return ret
    _socket.add_route('saveFileData', SaveFileData)
    
    def SaveImageData(data, auth, websocket):
        ret = _file_upload.SaveImageData(data['fileData'], config['web_server']['urls']['base_server'], removeOriginalFile = 1)
        return ret
    _socket.add_route('saveImageData', SaveImageData)

    def SaveImage(data, auth, websocket):
        ret = _image.Save(data['image'])
        ret = _route_parse.formatRet(data, ret)
        return ret
    _socket.add_route('saveImage', SaveImage)

addRoutes()
