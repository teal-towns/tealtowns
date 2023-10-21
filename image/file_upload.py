import base64
# import requests
import math
import os
from PIL import Image

import mongo_db

def CreateUploadsDirs():
    if not os.path.isdir('uploads'):
        os.mkdir('uploads')
    if not os.path.isdir('uploads/temp'):
        os.mkdir('uploads/temp')
    if not os.path.isdir('uploads/files'):
        os.mkdir('uploads/files')
    if not os.path.isdir('uploads/images'):
        os.mkdir('uploads/images')

def GetResizeDimensions(img, maxSize = 900):
    if img.width > img.height:
        width = maxSize
        height = math.floor(img.height * width / img.width)
    else:
        height = maxSize
        width = math.floor(img.width * height / img.height)
    return { 'width': width, 'height': height }

def HandleImage(filePath, baseUrl, filename = '', maxSize = 900, removeOriginalFile = 0):
    ret = { 'valid': 0, 'msg': '', 'url': '' }

    with Image.open(filePath) as img:
        if img.width > maxSize or img.height > maxSize:
            newDimensions = GetResizeDimensions(img, maxSize)
            # Preserve format: https://stackoverflow.com/questions/29374072/why-does-resizing-image-in-pillow-python-remove-image-format
            imgFormat = img.format
            img = img.resize((newDimensions['width'], newDimensions['height']))
            img.format = imgFormat
            # img.quality(80)
        if len(filename) < 1:
            filename = mongo_db.newObjectIdString()
            if img.format.lower() == 'png':
                filename += '.png'
            else:
                img.format = 'jpeg'
                filename += '.jpg'
        newFilePath = 'uploads/images/' + filename
        img.save(newFilePath)
        # ret['url'] = baseUrl + '/' + newFilePath
        ret['url'] = '/' + newFilePath
        ret['valid'] = 1

        if removeOriginalFile:
            os.remove(filePath)

    return ret

def SaveImageData(fileData, baseUrl, filename = '', maxSize = 900, dataFormat = 'uint8', removeOriginalFile = 0):
    # ret = { 'valid': 1, 'msg': '', 'url': '' }
    retFile = SaveFileData(fileData, baseUrl, filename, dataFormat = dataFormat)
    return HandleImage(retFile['filePath'], baseUrl, filename, maxSize, removeOriginalFile)
    # return ret

def SaveFileData(fileData, baseUrl, filename = '', dataFormat = 'uint8'):
    ret = { 'valid': 1, 'msg': '', 'filePath': '', 'url': '' }

    extension = ''
    indexPos = filename.rfind('.');
    if indexPos > -1:
        extension = filename[slice((indexPos + 1), len(filename))]
    filenameNew = mongo_db.newObjectIdString()
    if extension != '':
        filenameNew += '.' + extension
    CreateUploadsDirs()
    filePath = os.path.join('uploads/files/', filenameNew)
    with open(filePath, 'wb') as f:
        if dataFormat == 'uint8':
            for byte in fileData:
                f.write(byte.to_bytes(1, byteorder='big'))
        else:
            f.write(fileData)
    ret['filePath'] = filePath
    # ret['url'] = baseUrl + '/' + filePath
    ret['url'] = '/' + filePath

    return ret

def FormFilename(mime):
    filename = mongo_db.newObjectIdString()
    if mime == 'image/png':
        filename += '.png'
    else:
        filename += '.jpg'
    return filename

def GetImageData(imageUrl):
    imageUrl = imageUrl.strip()
    try:
        # Assume file is local, in uploads folder.
        # TODO - parse url and handle remote ones accordingly.
        # imageData = base64.b64encode(requests.get(imageUrl).content)
        posSlash = imageUrl.rindex("/")
        filename = imageUrl[slice((posSlash + 1), len(imageUrl))]
        filePath = 'uploads/images/' + filename
        # https://www.codespeedy.com/convert-image-to-base64-string-in-python/
        with open(filePath, "rb") as file:
            imageData = base64.b64encode(file.read()).decode('utf-8')
        # # We actually want them as string here, not bytes.
        # with open(filePath, "r") as file:
        #     imageData = file.read()
    except Exception as e:
        print ("GetImageData exception", e)
        imageData = ""
    return imageData
