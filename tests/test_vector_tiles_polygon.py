import geopandas
from fiona.drvsupport import supported_drivers
supported_drivers['KML'] = 'rw'
import json
import random

from vector_tiles import vector_tiles_polygon as _vector_tiles_polygon

# TODO: Tests started failing on 2024.09.06 - dependency update?
#  FAILED tests/test_vector_tiles_polygon.py::test_GetInfo - AttributeError: module 'fiona' has no attribute 'path'
# def test_GetInfo():
#     filePath = './test_coordinates/darien_phase_1_Boca_De_Cupe.kml'
#     ret = _vector_tiles_polygon.GetPolygonFileTilesInfo(filePath)

#     assert ret['areaHa'] == 342.563

#     assert ret['bounds'] == {
#         'min': [ -77.61458, 8.02356, 0, ],
#         'max': [ -77.58858, 8.0401, 0, ],
#     }

#     assert len(ret['tileNumbersZoom16']) == 92
#     assert ret['tileNumbersZoom16'][0] == 3664151988
#     assert ret['tileNumbersZoom16'][91] == 3665593783
