import simplejson as json
import zipfile
import os
import geopandas
from fiona.drvsupport import supported_drivers
import shapely
import shutil

# from common import bucket as _bucket
from common import math_polygon as _math_polygon
import lodash
import log
import ml_config
from image import file_upload as _file_upload

_config = ml_config.get_config()

# TODO - add google auth to config and add back in.
# def UploadFileDataToBucket(fileData, fileType = None, dataFormat = 'uint8',
#     fileFormat = 'bytes', title = None, fileName = None):
#     if fileType is None or len(fileType) < 1:
#         if (fileName is not None and len(fileName) > 0):
#             fileType = lodash.getFileExtension(fileName)
#         else:
#             fileType = 'geojson'
#     fileName = fileName if (fileName is not None and len(fileName) > 0) else lodash.random_string() + '.' + fileType
#     title = title if (title is not None and len(title) > 0) else lodash.random_string()

#     ret = { 'valid': 1, 'msg': '', 'fileUrl': '', 'blobName': '', 'title': '', }

#     filePath = 'uploads/temp_' + fileName
#     with open(filePath, 'wb') as file:
#         if dataFormat == 'uint8':
#             for byte in fileData:
#                 file.write(byte.to_bytes(1, byteorder='big'))
#         else:
#             file.write(fileData)
#     geojson = FileToGeojson(filePath, fileType)
#     fileName = lodash.random_string() + '.geojson'
#     retBucket = _bucket.UploadFileFromString(geojson, fileName = fileName)
#     ret['fileUrl'] = retBucket['url']
#     ret['blobName'] = retBucket['blobName']
#     ret['title'] = title
#     # delete file
#     os.remove(filePath)

#     return ret

def FileToGeojson(filePath, fileType = 'geojson'):
    ret = { 'valid': 0, 'msg': '' }
    geojson = None
    if fileType == 'kml':
        try:
            supported_drivers['KML'] = 'rw'
            geoDataFrame = geopandas.read_file(filePath, driver = 'KML')
            geojson = geoDataFrameToGeojson(geoDataFrame)
        except Exception as err:
            log.log('warn', 'upload_coordinates.FileToGeojson KML parse error')
            print(err)
            ret['valid'] = 0
            ret['msg'] = 'KML parse error'
    elif fileType == 'kmz':
        try:
            geojson = KMZToGeojson(filePath)
        except Exception as err:
            log.log('warn', 'upload_coordinates.FileToGeojson KMZ parse error')
            print(err)
            ret['valid'] = 0
            ret['msg'] = 'KMZ parse error'
    elif fileType == 'zip':
        try:
            geojson = SHPZipToGeojson(filePath)
        except Exception as err:
            log.log('warn', 'upload_coordinates.FileToGeojson shp zip parse error')
            print(err)
            ret['valid'] = 0
            ret['msg'] = 'shp zip parse error'
    else:
        try:
            geoDataFrame = geopandas.read_file(filePath)
            geojson = geoDataFrameToGeojson(geoDataFrame)
        except Exception as err:
            log.log('warn', 'upload_coordinates.FileToGeojson geojson parse error')
            print(err)
            ret['valid'] = 0
            ret['msg'] = 'geojson parse error'
    return geojson

def UploadData(filePath, fileType = 'geojson', dataFormat = 'uint8', maxCoordinatesCount = None,
    logCountCoordinates = 0):
    ret = { 'valid': 1, 'msg': '', 'parcels': [] }
    geojson = FileToGeojson(filePath, fileType)
    ret = GeojsonToParcels(geojson, maxCoordinatesCount = maxCoordinatesCount,
        logCountCoordinates = logCountCoordinates)      
    for index, parcel in enumerate(ret['parcels']):
        ret['parcels'][index]['bounds'] = _math_polygon.MinMaxBounds(ret['parcels'][index]['coordinates'])['bounds']
    return ret

def CommonPolygonFilesToParcel(filePath, maxCoordinatesCount = None, logCountCoordinates = 0):
    geoDataFrame = geopandas.read_file(filePath)
    geojson = geoDataFrameToGeojson(geoDataFrame)

    return GeojsonToParcels(geojson, maxCoordinatesCount = maxCoordinatesCount,
            logCountCoordinates = logCountCoordinates)

def GeojsonToParcels(fileData, maxCoordinatesCount = None, minCoordinatesPerParcel = 3, maxCoordinatesPerParcel = 20000, logCountCoordinates = 0):
    if maxCoordinatesCount is None:
        maxCoordinatesCount = 50000
    ret = { 'parcels': [], 'skippedCount': 0, 'valid': 1, 'msg': '', 'skippedCountMinCoordinatesPerParcel': 0, 
    'skippedCountMaxCoordinatesPerParcel':0, 'skippedCountInvalidCoordinates': 0, 'totalCoordinates': 0 }
    data = json.loads(fileData)
    if 'features' not in data or len(data['features']) < 1:
        ret['valid'] = 0
        ret['msg'] = 'This file contains no geo features.'
    else:
        parcels = []
        skippedCount = 0
        skippedCountMinCoordinatesPerParcel = 0
        skippedCountMaxCoordinatesPerParcel = 0
        skippedCountInvalidCoordinates = 0
        for feature in data['features']:
            parcelsCoordinates = []
            name = feature['properties']['name'] if \
                ('properties' in feature and 'name' in feature['properties']) else ''
            if 'geometry' in feature and 'type' in feature['geometry'] and \
                'coordinates' in feature['geometry']:
                if feature['geometry']['type'].lower() == 'polygon':
                    # geojson nests coordinates in an array..
                    coordinatesTemp = feature['geometry']['coordinates'][0]
                    retCoordinatesValid = ValidateCoordinates(coordinatesTemp)
                    coordinatesTemp = retCoordinatesValid['coordinates']
                    parcelsCoordinates.append(coordinatesTemp)
                elif feature['geometry']['type'].lower() == 'multipolygon':
                    multiPolygonCoordinates = [coordinates for coordinates in feature['geometry']['coordinates']]
                    for coordinatesGroup in multiPolygonCoordinates:
                        coordinatesTemp = coordinatesGroup[0]
                        retCoordinatesValid = ValidateCoordinates(coordinatesTemp)
                        parcelsCoordinates.append(coordinatesTemp)

                for parcelCoordinates in parcelsCoordinates:
                    if len(parcelCoordinates) <= maxCoordinatesPerParcel and len(parcelCoordinates) >= minCoordinatesPerParcel and \
                            retCoordinatesValid['valid']:
                                parcels.append({
                                    'coordinates': parcelCoordinates,
                                    'name': name,
                                })
                    else:
                        skippedCount += 1
                        if len(parcelCoordinates) < minCoordinatesPerParcel:
                                skippedCountMinCoordinatesPerParcel += 1
                        elif len(parcelCoordinates) > maxCoordinatesPerParcel:
                                skippedCountMaxCoordinatesPerParcel += 1
                        elif not retCoordinatesValid['valid']:
                                skippedCountInvalidCoordinates += 1
                                ret['invalidCoordinatesMsg'] = retCoordinatesValid['msg']
                        

        ret['parcels'] = parcels
        ret['skippedCount'] = skippedCount
        ret['skippedCountMinCoordinatesPerParcel'] = skippedCountMinCoordinatesPerParcel
        ret['skippedCountMaxCoordinatesPerParcel'] = skippedCountMaxCoordinatesPerParcel
        ret['skippedCountInvalidCoordinates'] = skippedCountInvalidCoordinates
        ret['msg'] = FormMessage(ret, minCoordinatesPerParcel, maxCoordinatesPerParcel)
    return ret

def KMLToParcels(filePath, maxCoordinatesCount = None, logCountCoordinates = 0):
    if maxCoordinatesCount is None:
        # arbitrary number that gets away with 413:EntityTooLarge error in the frontend for test files
        maxCoordinatesCount = 50000 
    supported_drivers['KML'] = 'rw'
    geoDataFrame = geopandas.read_file(filePath, driver = 'KML')
    geojson = geoDataFrameToGeojson(geoDataFrame)
    return GeojsonToParcels(geojson, maxCoordinatesCount = maxCoordinatesCount,
        logCountCoordinates = logCountCoordinates)

def KMZToGeojson(filePath):
    saveTo = 'uploads/kml_' + lodash.random_string()
    kmlFilePath = UnzipAndReturnFilePath(filePath, saveTo, 'kml')
    supported_drivers['KML'] = 'rw'
    geoDataFrame = geopandas.read_file(kmlFilePath, driver = 'KML')
    geojson = geoDataFrameToGeojson(geoDataFrame)

    # Delete directory after read 
    try:
        shutil.rmtree(saveTo)
    except shutil.Error as e:
        print("Error deleting unzip kmz directory: %s : %s" % (saveTo, e.strerror))
    return geojson

def KMZToParcels(filePath, maxCoordinatesCount = None, logCountCoordinates = 0):
    geojson = KMZToGeojson(filePath)
    return GeojsonToParcels(geojson, maxCoordinatesCount = maxCoordinatesCount,
        logCountCoordinates = logCountCoordinates)

def SHPZipToGeojson(filePath, removeFilePath = 0):
    saveTo = 'uploads/shapefile_' + lodash.random_string()
    shpFilePath = UnzipAndReturnFilePath(filePath, saveTo, 'shp')
    # Read and convert .shp file to geojson with geopandas 
    geoDataFrame = geopandas.read_file(shpFilePath)
    geojson = geoDataFrameToGeojson(geoDataFrame)
    if removeFilePath:
        # Remove temp file if it's not in ./test_coordinates/ folder
        directory = filePath.split('/')[1]
        if directory != 'test_coordinates':
            os.remove(filePath)
    # Remove shapefile folder after use
    try:
        shutil.rmtree(saveTo)
    except shutil.Error as e:
        print("Error deleting shapefile directory: %s : %s" % (saveTo, e.strerror))
    return geojson

def SHPZipToParcels(filePath,  maxCoordinatesCount = None, logCountCoordinates = 0):
    geojson = SHPZipToGeojson(filePath, removeFilePath = 1)
    return GeojsonToParcels(geojson, maxCoordinatesCount = maxCoordinatesCount, 
    logCountCoordinates = logCountCoordinates)

def FormMessage(ret, minCoordinatesPerParcel, maxCoordinatesPerParcel):
    ret['msg'] = str(len(ret['parcels'])) + ' parcels.'
    if ret['skippedCount'] > 0:
        ret['msg'] += ' ' + str(ret['skippedCount']) + ' skipped.'
        if ret['skippedCountMinCoordinatesPerParcel'] > 0:
            ret['msg'] += ' ' + str(ret['skippedCountMinCoordinatesPerParcel']) + \
                ' too few coordinates; ' + str(minCoordinatesPerParcel) + \
                ' is the min number of coordinates.'
        if ret['skippedCountMaxCoordinatesPerParcel'] > 0:
            ret['msg'] += ' ' + str(ret['skippedCountMaxCoordinatesPerParcel']) + \
                ' too many coordinates; ' + str(maxCoordinatesPerParcel) + \
                ' is the max number of coordinates.'
        if ret['skippedCountInvalidCoordinates'] > 0:
            ret['msg'] += ' ' + str(ret['skippedCountInvalidCoordinates']) + \
                ' invalid.'
            if 'invalidCoordinatesMsg' in ret:
                ret['msg'] += ' ' + ret['invalidCoordinatesMsg']
    return ret['msg']

def ValidateCoordinates(coordinates):
    ret = { 'coordinates': coordinates, 'valid': 1, 'msg': '' }
    # Ensure start is the same as the end.
    lastIndex = len(coordinates) - 1
    if coordinates[0] != coordinates[lastIndex]:
        ret['valid'] = 0
        coordinates.append(coordinates[0])
        ret['coordinates'] = coordinates
        ret['msg'] = 'coordinates do not form enclosed polygon'
    
    # Ensure polygon area is bigger than 0.001 ha (10 m^2)
    area = _math_polygon.PolygonAreaLngLat(coordinates)
    if area < 10:
        ret['valid'] = 0
        ret['msg'] = 'polygon area is smaller than 0.001 ha'
    return ret

def ParcelsToGeojson(parcels):
    json = {
        "type": "FeatureCollection",
        "features": []
    }
    for parcel in parcels:
        json["features"].append({
            "type": "Feature",
            "properties": {},
            "geometry": {
                "type": "Polygon",
                "coordinates": [ parcel["coordinates"] ]
            }
        })
    return json

def WriteGeojsonToFile(geojson, fileName = '', parcels = None, polygonsLngLats = None):
    _file_upload.CreateUploadsDirs()
    if polygonsLngLats is not None:
        parcels = []
        for polygonLngLats in polygonsLngLats:
            parcels.append({ 'coordinates': polygonLngLats })
    if parcels is not None:
        geojson = ParcelsToGeojson(parcels)
    ret = { 'valid': 1, 'fileUrl': '' }
    if fileName == '':
        fileName = lodash.random_string()
    filePath = os.path.join('uploads/temp/', fileName  + '.geojson')
    with open(filePath, 'w') as f:
        f.write(json.dumps(geojson, indent = 2))
    ret['fileUrl'] = _config['web_server']['urls']['base_server'] + '/' + filePath
    ret['filePath'] = filePath
    return ret

def UnzipAndReturnFilePath(filePath, saveTo, targetFileType):
    # Unzip
    unzippedFile = zipfile.ZipFile(filePath)
    # Extract all files and get target type file name
    unzippedFile.extractall(path = saveTo)
    fileNames = unzippedFile.namelist()
    for fileName in fileNames:
        if fileName.endswith(targetFileType):
            targetFileName = fileName
            break
    targetFilePath = saveTo + '/' + targetFileName
    return targetFilePath

def geoDataFrameToGeojson(geoDataFrame):
    # reproject to EPSG:4326 Reprojection reference -> https://geopandas.org/en/v0.4.0/projections.html
    geoDataFrame = geoDataFrame.to_crs('EPSG:4326')
    # round coordinates to 6 decimal points
    truncateCoordinates = lambda *coords: [round(coord,6) for coord in coords[:2]]
    geoDataFrame.geometry = [shapely.ops.transform(truncateCoordinates, geo) for geo in geoDataFrame.geometry]
    # Set tolerence to 1 meter. Accuracy-Decimal referece http://wiki.gis.com/wiki/index.php/Decimal_degrees
    geoDataFrame =  geoDataFrame.simplify(1e-5)
    geojson = geoDataFrame.to_json()
    return geojson
    
""" 
TODO: Mapbox takes vector tile, which can be created via 
ogr2ogr -of MVT PATH_TO_THIS_SHAPEFILES_DIRECTORY_OF_TILES uploaded_file.kml
"""