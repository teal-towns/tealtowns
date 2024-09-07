import glob
import re

# from common import bucket as _bucket
from common import upload_coordinates
import datetime

def uploadFile(filename, fileType, dataFormat = 'uint8'):
    filePath = "./test_coordinates/" + filename
    timingStart = datetime.datetime.now()
    ret = upload_coordinates.UploadData(filePath, fileType, dataFormat = dataFormat)
    timingEnd = datetime.datetime.now()
    ret['start'] = timingStart
    ret['end'] = timingEnd
    return ret

# TODO: tests started failing on 2024.09.06 - dependency update?
# FAILED tests/test_upload_coordinates.py::test_validKMLs - TypeError: Input string must be text, not bytes
# FAILED tests/test_upload_coordinates.py::test_validKMZs - TypeError: Input string must be text, not bytes
# FAILED tests/test_upload_coordinates.py::test_validSHPs - TypeError: Input string must be text, not bytes
# FAILED tests/test_upload_coordinates.py::test_validGeojsons - TypeError: Input string must be text, not bytes

# def test_validKMLs():
#     ret = uploadFile('darien_phase_1_Boca_De_Cupe.kml', 'kml')
#     assert ret['valid'] == 1
#     assert len(ret['parcels']) == 1
#     assert (ret['end'] - ret['start']).total_seconds() < 0.2

#     # commenting out big files for now for test performance
#     # # Big file
#     # ret = uploadFile('PA_Rivers60m_and_SugarPlantation.kml', 'kml')
#     # assert ret['valid'] == 1
#     # assert len(ret['parcels']) == 111
#     # assert (ret['end'] - ret['start']).total_seconds() < 0.1

# def test_validKMZs():
#     ret = uploadFile('santa_fe_147ha.kmz', 'kmz')
#     assert ret['valid'] == 1
#     assert len(ret['parcels']) == 1
#     assert (ret['end'] - ret['start']).total_seconds() < 0.2

#     ret = uploadFile('Eco-Venao-Site.kmz', 'kmz')
#     assert ret['valid'] == 1
#     assert len(ret['parcels']) == 4
#     assert (ret['end'] - ret['start']).total_seconds() < 0.2

#     # kmz with namespaces
#     ret = uploadFile('Gabriela-Nogueira-119ha.kmz', 'kmz')
#     assert ret['valid'] == 1
#     assert len(ret['parcels']) == 1
#     assert (ret['end'] - ret['start']).total_seconds() < 0.2
    
#     # kmz with 2 valid polygons
#     ret = uploadFile('Cambodia_Project_Area.kmz', 'kmz')
#     assert ret['valid'] == 1
#     assert len(ret['parcels']) == 2
#     assert (ret['end'] - ret['start']).total_seconds() < 0.2
    
#     # Check kml file folder & files are deleted
#     path = './uploads/'
#     for name in glob.glob(path + '*'):
#         assert(re.search(path+'kml_*', name) == None)
    
# def test_validSHPs():
#     ret = uploadFile('TPC_planting.zip', 'zip')
#     assert ret['valid'] == 1
#     assert len(ret['parcels']) == 6
#     assert (ret['end'] - ret['start']).total_seconds() < 0.3

#     # commenting out big files for now for test performance
#     ret = uploadFile('areas_restauracion_predios_final_2021.zip', 'zip')
#     assert ret['valid'] == 1
#     assert (ret['end'] - ret['start']).total_seconds() < 2
#     assert len(ret['parcels']) == 659
    
#     # test shapefile with invalid coordinates because polygon area is smaller than 0.001 ha
#     # ret = uploadFile('Shipibo.zip', 'zip')
#     # assert ret['valid'] == 1
#     # assert len(ret['parcels']) == 184
#     # assert(ret['message'] == '184 parcels. 1 skipped. 1 invalid. polygon area is smaller than 0.001 ha')
#     # assert (ret['end'] - ret['start']).total_seconds() < 0.3

#     # Check shapefile folder & files are deleted
#     path = './uploads/'
#     for name in glob.glob(path + '*'):
#         assert(re.search(path+'shapefile_*', name) == None)
        
# def test_validGeojsons():
#     ret = uploadFile('8im9bqdEQH.geojson', 'geojson')
#     assert ret['valid'] == 1
#     assert len(ret['parcels']) == 28
#     assert (ret['end'] - ret['start']).total_seconds() < 0.2

#     # MultiPolygon geojson file
#     ret = uploadFile('tanzania_river_mock.geojson', 'geojson')
#     assert ret['valid'] == 1
#     assert len(ret['parcels']) == 2
#     assert (ret['end'] - ret['start']).total_seconds() < 0.2

# TODO: fix this test
# def test_emptyPolygon():
#     ret = uploadFile('EmptyPolygon.kml', 'kml')
#     assert ret['valid'] == 0
#     assert ret['message'] == 'This file contains no geo features.'
#     assert len(ret['parcels']) == 0
#     assert (ret['end'] - ret['start']).total_seconds() < 0.1

# TODO - add bucket to config and uncomment
# def UploadToBucket(filePath, fileType):
#     fileData = None
#     with open(filePath, 'rb') as file:
#         fileData = file.read()
#     ret = upload_coordinates.UploadFileDataToBucket(fileData, fileType = fileType)
#     # print ('ret', ret['fileUrl'])
#     assert len(ret['fileUrl']) > 0
#     assert ret['valid'] == 1
#     retRead = _bucket.ReadFile(ret['blobName'])
#     assert retRead['valid'] == 1
#     retDelete = _bucket.DeleteFile(ret['blobName'])
#     assert retDelete['valid'] == 1

# def test_uploadBucket():
#     filePath = './test_coordinates/Gabriela-Nogueira-119ha.kmz'
#     UploadToBucket(filePath, 'kmz')

#     filePath = './test_coordinates/darien_phase_1_Boca_De_Cupe.kml'
#     UploadToBucket(filePath, 'kml')

#     filePath = './test_coordinates/PuyanawaLand.geojson'
#     UploadToBucket(filePath, 'geojson')

#     filePath = './test_coordinates/TPC_planting.zip'
#     UploadToBucket(filePath, 'zip')

# def test_uploadBucketUint8():
#     ret = upload_coordinates.UploadFileDataToBucket(_fileData['kml1'])
#     # print ('ret', ret['fileUrl'])
#     assert len(ret['fileUrl']) > 0
#     assert ret['valid'] == 1
#     retRead = _bucket.ReadFile(ret['blobName'])
#     assert retRead['valid'] == 1
#     retDelete = _bucket.DeleteFile(ret['blobName'])
#     assert retDelete['valid'] == 1

_fileData = {
    'kml1': [60, 63, 120, 109, 108, 32, 118, 101, 114, 115, 105, 111, 110, 61, 34, 49, 46, 48, 34, 32, 101, 110, 99, 111, 100, 105, 110, 103, 61, 34, 85, 84, 70, 45, 56, 34, 63, 62, 10, 60, 107, 109, 108, 32, 120, 109, 108, 110, 115, 61, 34, 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 111, 112, 101, 110, 103, 105, 115, 46, 110, 101, 116, 47, 107, 109, 108, 47, 50, 46, 50, 34, 32, 120, 109, 108, 110, 115, 58, 103, 120, 61, 34, 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 103, 111, 111, 103, 108, 101, 46, 99, 111, 109, 47, 107, 109, 108, 47, 101, 120, 116, 47, 50, 46, 50, 34, 32, 120, 109, 108, 110, 115, 58, 107, 109, 108, 61, 34, 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 111, 112, 101, 110, 103, 105, 115, 46, 110, 101, 116, 47, 107, 109, 108, 47, 50, 46, 50, 34, 32, 120, 109, 108, 110, 115, 58, 97, 116, 111, 109, 61, 34, 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 119, 51, 46, 111, 114, 103, 47, 50, 48, 48, 53, 47, 65, 116, 111, 109, 34, 62, 10, 60, 68, 111, 99, 117, 109, 101, 110, 116, 62, 10, 9, 60, 110, 97, 109, 101, 62, 68, 97, 114, 105, 101, 110, 32, 80, 104, 97, 115, 101, 32, 49, 32, 66, 111, 99, 97, 32, 68, 101, 32, 67, 117, 112, 101, 46, 107, 109, 122, 60, 47, 110, 97, 109, 101, 62, 10, 9, 60, 83, 116, 121, 108, 101, 32, 105, 100, 61, 34, 105, 110, 108, 105, 110, 101, 34, 62, 10, 9, 9, 60, 76, 105, 110, 101, 83, 116, 121, 108, 101, 62, 10, 9, 9, 9, 60, 99, 111, 108, 111, 114, 62, 102, 102, 48, 48, 48, 48, 102, 102, 60, 47, 99, 111, 108, 111, 114, 62, 10, 9, 9, 9, 60, 119, 105, 100, 116, 104, 62, 50, 60, 47, 119, 105, 100, 116, 104, 62, 10, 9, 9, 60, 47, 76, 105, 110, 101, 83, 116, 121, 108, 101, 62, 10, 9, 9, 60, 80, 111, 108, 121, 83, 116, 121, 108, 101, 62, 10, 9, 9, 9, 60, 102, 105, 108, 108, 62, 48, 60, 47, 102, 105, 108, 108, 62, 10, 9, 9, 60, 47, 80, 111, 108, 121, 83, 116, 121, 108, 101, 62, 10, 9, 60, 47, 83, 116, 121, 108, 101, 62, 10, 9, 60, 83, 116, 121, 108, 101, 77, 97, 112, 32, 105, 100, 61, 34, 105, 110, 108, 105, 110, 101, 48, 34, 62, 10, 9, 9, 60, 80, 97, 105, 114, 62, 10, 9, 9, 9, 60, 107, 101, 121, 62, 110, 111, 114, 109, 97, 108, 60, 47, 107, 101, 121, 62, 10, 9, 9, 9, 60, 115, 116, 121, 108, 101, 85, 114, 108, 62, 35, 105, 110, 108, 105, 110, 101, 49, 60, 47, 115, 116, 121, 108, 101, 85, 114, 108, 62, 10, 9, 9, 60, 47, 80, 97, 105, 114, 62, 10, 9, 9, 60, 80, 97, 105, 114, 62, 10, 9, 9, 9, 60, 107, 101, 121, 62, 104, 105, 103, 104, 108, 105, 103, 104, 116, 60, 47, 107, 101, 121, 62, 10, 9, 9, 9, 60, 115, 116, 121, 108, 101, 85, 114, 108, 62, 35, 105, 110, 108, 105, 110, 101, 60, 47, 115, 116, 121, 108, 101, 85, 114, 108, 62, 10, 9, 9, 60, 47, 80, 97, 105, 114, 62, 10, 9, 60, 47, 83, 116, 121, 108, 101, 77, 97, 112, 62, 10, 9, 60, 83, 116, 121, 108, 101, 32, 105, 100, 61, 34, 105, 110, 108, 105, 110, 101, 49, 34, 62, 10, 9, 9, 60, 76, 105, 110, 101, 83, 116, 121, 108, 101, 62, 10, 9, 9, 9, 60, 99, 111, 108, 111, 114, 62, 102, 102, 48, 48, 48, 48, 102, 102, 60, 47, 99, 111, 108, 111, 114, 62, 10, 9, 9, 9, 60, 119, 105, 100, 116, 104, 62, 50, 60, 47, 119, 105, 100, 116, 104, 62, 10, 9, 9, 60, 47, 76, 105, 110, 101, 83, 116, 121, 108, 101, 62, 10, 9, 9, 60, 80, 111, 108, 121, 83, 116, 121, 108, 101, 62, 10, 9, 9, 9, 60, 102, 105, 108, 108, 62, 48, 60, 47, 102, 105, 108, 108, 62, 10, 9, 9, 60, 47, 80, 111, 108, 121, 83, 116, 121, 108, 101, 62, 10, 9, 60, 47, 83, 116, 121, 108, 101, 62, 10, 9, 60, 80, 108, 97, 99, 101, 109, 97, 114, 107, 62, 10, 9, 9, 60, 110, 97, 109, 101, 62, 68, 97, 114, 105, 101, 110, 32, 80, 104, 97, 115, 101, 32, 49, 32, 66, 111, 99, 97, 32, 68, 101, 32, 67, 117, 112, 101, 60, 47, 110, 97, 109, 101, 62, 10, 9, 9, 60, 115, 116, 121, 108, 101, 85, 114, 108, 62, 35, 105, 110, 108, 105, 110, 101, 48, 60, 47, 115, 116, 121, 108, 101, 85, 114, 108, 62, 10, 9, 9, 60, 80, 111, 108, 121, 103, 111, 110, 62, 10, 9, 9, 9, 60, 116, 101, 115, 115, 101, 108, 108, 97, 116, 101, 62, 49, 60, 47, 116, 101, 115, 115, 101, 108, 108, 97, 116, 101, 62, 10, 9, 9, 9, 60, 111, 117, 116, 101, 114, 66, 111, 117, 110, 100, 97, 114, 121, 73, 115, 62, 10, 9, 9, 9, 9, 60, 76, 105, 110, 101, 97, 114, 82, 105, 110, 103, 62, 10, 9, 9, 9, 9, 9, 60, 99, 111, 111, 114, 100, 105, 110, 97, 116, 101, 115, 62, 10, 9, 9, 9, 9, 9, 9, 45, 55, 55, 46, 53, 57, 53, 48, 50, 48, 51, 51, 55, 48, 49, 48, 52, 49, 44, 56, 46, 48, 51, 57, 56, 51, 56, 54, 54, 54, 56, 54, 49, 48, 48, 55, 44, 48, 32, 45, 55, 55, 46, 54, 48, 51, 56, 51, 54, 52, 57, 49, 49, 55, 55, 50, 56, 44, 56, 46, 48, 52, 48, 49, 48, 55, 50, 57, 55, 48, 55, 50, 50, 56, 52, 44, 48, 32, 45, 55, 55, 46, 54, 48, 55, 53, 50, 56, 57, 57, 56, 56, 49, 53, 51, 51, 44, 56, 46, 48, 51, 57, 57, 57, 49, 52, 57, 55, 48, 56, 51, 52, 53, 54, 44, 48, 32, 45, 55, 55, 46, 54, 48, 55, 55, 51, 50, 54, 49, 57, 56, 51, 50, 50, 57, 44, 56, 46, 48, 51, 57, 56, 57, 52, 53, 56, 56, 48, 54, 48, 56, 55, 57, 44, 48, 32, 45, 55, 55, 46, 54, 48, 55, 56, 56, 54, 48, 53, 54, 55, 49, 51, 56, 50, 44, 56, 46, 48, 51, 57, 56, 57, 54, 57, 48, 49, 57, 51, 51, 54, 53, 57, 44, 48, 32, 45, 55, 55, 46, 54, 48, 56, 50, 51, 57, 53, 57, 57, 55, 54, 51, 57, 50, 44, 56, 46, 48, 51, 57, 56, 52, 57, 49, 52, 51, 56, 53, 51, 48, 57, 57, 44, 48, 32, 45, 55, 55, 46, 54, 49, 51, 57, 54, 50, 55, 53, 53, 57, 48, 52, 51, 44, 56, 46, 48, 51, 56, 51, 51, 53, 49, 56, 53, 48, 53, 54, 53, 54, 57, 44, 48, 32, 45, 55, 55, 46, 54, 49, 52, 53, 56, 50, 49, 51, 54, 52, 51, 52, 55, 49, 44, 56, 46, 48, 51, 53, 50, 54, 57, 48, 55, 57, 53, 56, 57, 50, 56, 52, 44, 48, 32, 45, 55, 55, 46, 54, 49, 52, 53, 51, 51, 56, 51, 54, 57, 49, 54, 55, 53, 44, 56, 46, 48, 51, 53, 49, 50, 48, 57, 57, 56, 56, 56, 48, 50, 52, 50, 44, 48, 32, 45, 55, 55, 46, 54, 49, 52, 52, 56, 53, 54, 50, 53, 56, 50, 56, 56, 57, 44, 56, 46, 48, 51, 52, 56, 55, 51, 55, 48, 51, 55, 49, 54, 51, 55, 50, 44, 48, 32, 45, 55, 55, 46, 54, 49, 52, 50, 56, 57, 53, 54, 48, 57, 56, 50, 52, 51, 44, 56, 46, 48, 51, 52, 51, 50, 57, 54, 51, 57, 51, 52, 51, 51, 52, 49, 44, 48, 32, 45, 55, 55, 46, 54, 49, 52, 50, 57, 48, 50, 54, 50, 55, 55, 53, 56, 49, 44, 56, 46, 48, 51, 52, 50, 51, 48, 54, 54, 48, 53, 56, 50, 52, 49, 51, 44, 48, 32, 45, 55, 55, 46, 54, 49, 51, 51, 53, 48, 51, 55, 51, 48, 49, 56, 48, 50, 44, 56, 46, 48, 51, 49, 50, 52, 49, 56, 57, 56, 57, 48, 53, 53, 50, 57, 44, 48, 32, 45, 55, 55, 46, 54, 49, 51, 50, 57, 54, 52, 50, 57, 51, 55, 49, 52, 54, 44, 56, 46, 48, 51, 49, 48, 52, 50, 53, 53, 48, 56, 51, 56, 50, 52, 52, 44, 48, 32, 45, 55, 55, 46, 54, 49, 51, 50, 51, 56, 55, 54, 48, 50, 56, 50, 55, 53, 44, 56, 46, 48, 51, 48, 54, 57, 51, 53, 56, 55, 50, 50, 57, 48, 57, 51, 44, 48, 32, 45, 55, 55, 46, 54, 49, 51, 48, 50, 56, 49, 57, 50, 55, 52, 56, 49, 55, 44, 56, 46, 48, 50, 57, 55, 57, 57, 51, 53, 57, 56, 52, 54, 56, 51, 50, 44, 48, 32, 45, 55, 55, 46, 54, 49, 50, 55, 51, 48, 57, 51, 56, 57, 50, 51, 57, 57, 44, 56, 46, 48, 50, 57, 48, 53, 55, 49, 57, 48, 52, 48, 55, 56, 50, 53, 44, 48, 32, 45, 55, 55, 46, 54, 49, 50, 54, 51, 51, 52, 51, 52, 48, 48, 50, 57, 51, 44, 56, 46, 48, 50, 56, 55, 49, 49, 48, 52, 54, 54, 49, 49, 54, 50, 49, 44, 48, 32, 45, 55, 55, 46, 54, 49, 50, 53, 51, 51, 55, 51, 54, 51, 52, 50, 53, 54, 44, 56, 46, 48, 50, 56, 53, 49, 51, 48, 48, 55, 56, 50, 48, 50, 51, 57, 44, 48, 32, 45, 55, 55, 46, 54, 49, 50, 51, 56, 48, 56, 51, 57, 57, 52, 52, 50, 52, 44, 56, 46, 48, 50, 56, 49, 54, 53, 56, 49, 48, 50, 57, 51, 53, 56, 49, 44, 48, 32, 45, 55, 55, 46, 54, 49, 49, 48, 51, 57, 52, 48, 56, 52, 57, 56, 49, 54, 44, 56, 46, 48, 50, 53, 50, 57, 56, 50, 57, 53, 53, 55, 48, 49, 50, 49, 44, 48, 32, 45, 55, 55, 46, 54, 49, 48, 57, 51, 55, 55, 55, 53, 50, 49, 57, 52, 52, 44, 56, 46, 48, 50, 53, 49, 52, 57, 50, 54, 48, 56, 56, 48, 55, 55, 54, 44, 48, 32, 45, 55, 55, 46, 54, 48, 55, 56, 55, 49, 51, 52, 55, 54, 51, 51, 52, 50, 44, 56, 46, 48, 50, 51, 55, 48, 57, 53, 50, 57, 57, 51, 57, 52, 54, 44, 48, 32, 45, 55, 55, 46, 54, 48, 55, 54, 55, 49, 53, 48, 51, 55, 52, 57, 53, 44, 56, 46, 48, 50, 51, 53, 54, 48, 54, 55, 51, 49, 55, 53, 52, 49, 44, 48, 32, 45, 55, 55, 46, 54, 48, 55, 53, 55, 49, 49, 48, 52, 54, 51, 55, 50, 55, 44, 56, 46, 48, 50, 51, 53, 54, 48, 54, 55, 49, 49, 52, 56, 50, 50, 51, 44, 48, 32, 45, 55, 55, 46, 54, 48, 52, 55, 56, 54, 55, 54, 56, 55, 48, 52, 56, 49, 44, 56, 46, 48, 50, 52, 48, 48, 56, 50, 51, 49, 49, 53, 56, 51, 48, 51, 44, 48, 32, 45, 55, 55, 46, 54, 48, 50, 50, 55, 50, 53, 48, 51, 51, 57, 56, 48, 56, 44, 56, 46, 48, 50, 54, 50, 57, 50, 52, 48, 56, 48, 55, 49, 51, 55, 52, 44, 48, 32, 45, 55, 55, 46, 54, 48, 50, 49, 55, 50, 56, 57, 57, 53, 50, 52, 57, 52, 44, 56, 46, 48, 50, 54, 51, 57, 49, 56, 55, 51, 52, 53, 51, 50, 48, 55, 44, 48, 32, 45, 55, 55, 46, 53, 57, 56, 55, 50, 56, 48, 55, 54, 57, 48, 49, 57, 57, 44, 56, 46, 48, 50, 57, 51, 55, 57, 53, 50, 57, 48, 52, 57, 50, 49, 44, 48, 32, 45, 55, 55, 46, 53, 57, 53, 55, 49, 57, 51, 57, 49, 49, 52, 55, 49, 56, 44, 56, 46, 48, 51, 50, 50, 54, 56, 48, 49, 54, 51, 51, 57, 57, 54, 52, 44, 48, 32, 45, 55, 55, 46, 53, 57, 53, 54, 49, 57, 49, 50, 52, 53, 50, 50, 44, 56, 46, 48, 51, 50, 50, 54, 56, 50, 50, 55, 48, 57, 48, 51, 51, 52, 44, 48, 32, 45, 55, 55, 46, 53, 57, 53, 51, 54, 56, 52, 50, 57, 57, 54, 57, 52, 55, 44, 56, 46, 48, 51, 50, 51, 49, 56, 52, 57, 57, 52, 53, 56, 49, 52, 54, 44, 48, 32, 45, 55, 55, 46, 53, 57, 53, 48, 49, 55, 52, 50, 51, 48, 52, 52, 50, 55, 44, 56, 46, 48, 51, 50, 51, 49, 57, 50, 52, 53, 51, 57, 53, 54, 56, 55, 44, 48, 32, 45, 55, 55, 46, 53, 57, 52, 55, 54, 54, 54, 53, 54, 48, 54, 52, 51, 56, 44, 56, 46, 48, 51, 50, 51, 54, 57, 53, 50, 55, 51, 50, 48, 54, 50, 50, 44, 48, 32, 45, 55, 55, 46, 53, 57, 52, 52, 54, 53, 53, 51, 49, 54, 48, 52, 48, 55, 44, 56, 46, 48, 51, 50, 52, 49, 57, 55, 52, 52, 54, 53, 51, 57, 55, 55, 44, 48, 32, 45, 55, 55, 46, 53, 57, 52, 50, 54, 52, 55, 53, 51, 53, 54, 54, 49, 53, 44, 56, 46, 48, 51, 50, 52, 54, 57, 55, 57, 54, 51, 51, 55, 56, 52, 49, 44, 48, 32, 45, 55, 55, 46, 53, 57, 51, 57, 49, 51, 52, 52, 54, 53, 52, 49, 48, 55, 44, 56, 46, 48, 51, 50, 53, 50, 48, 49, 54, 49, 52, 53, 50, 53, 53, 56, 44, 48, 32, 45, 55, 55, 46, 53, 57, 50, 48, 53, 51, 53, 57, 54, 49, 51, 55, 53, 55, 44, 56, 46, 48, 51, 50, 52, 50, 48, 51, 55, 53, 54, 49, 50, 48, 50, 50, 44, 48, 32, 45, 55, 55, 46, 53, 57, 50, 48, 48, 51, 50, 55, 53, 48, 57, 48, 54, 50, 44, 56, 46, 48, 51, 50, 52, 50, 48, 50, 56, 50, 51, 54, 53, 55, 55, 52, 44, 48, 32, 45, 55, 55, 46, 53, 56, 56, 54, 56, 53, 52, 49, 49, 50, 57, 52, 53, 49, 44, 56, 46, 48, 51, 49, 56, 50, 48, 55, 56, 56, 57, 49, 51, 56, 57, 57, 44, 48, 32, 45, 55, 55, 46, 53, 56, 56, 53, 56, 53, 50, 50, 55, 53, 53, 48, 53, 56, 44, 56, 46, 48, 51, 54, 53, 57, 57, 57, 52, 50, 55, 50, 51, 57, 56, 51, 44, 48, 32, 45, 55, 55, 46, 53, 57, 53, 48, 50, 48, 51, 51, 55, 48, 49, 48, 52, 49, 44, 56, 46, 48, 51, 57, 56, 51, 56, 54, 54, 54, 56, 54, 49, 48, 48, 55, 44, 48, 32, 10, 9, 9, 9, 9, 9, 60, 47, 99, 111, 111, 114, 100, 105, 110, 97, 116, 101, 115, 62, 10, 9, 9, 9, 9, 60, 47, 76, 105, 110, 101, 97, 114, 82, 105, 110, 103, 62, 10, 9, 9, 9, 60, 47, 111, 117, 116, 101, 114, 66, 111, 117, 110, 100, 97, 114, 121, 73, 115, 62, 10, 9, 9, 60, 47, 80, 111, 108, 121, 103, 111, 110, 62, 10, 9, 60, 47, 80, 108, 97, 99, 101, 109, 97, 114, 107, 62, 10, 60, 47, 68, 111, 99, 117, 109, 101, 110, 116, 62, 10, 60, 47, 107, 109, 108, 62, 10],
}
