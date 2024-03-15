
# import cv2
# import numpy as np
# import os
# from pathlib import Path

from mapbox import mapbox_polygon as _mapbox_polygon
# from land_vision.urban_tree_detection.evaluate import get_pred_locs
# from land_vision.urban_tree_detection.models import SFANet as SFANet
# from land_vision.urban_tree_detection.preprocess import preprocess_RGB
from land_vision.urban_tree_detection import urban_trees as _urban_trees
import mongo_mock as _mongo_mock

_mongo_mock.InitAllCollections()

# from land_vision import land_vision as _land_vision

# def test_seeLand():
#     imageUrl = 'https://ultralytics.com/images/bus.jpg'
#     imageUrl = './uploads/bus.jpg'

#     lngLat = [-122.033802, 37.977362]
#     zoom = 16
#     # zoom = 17
#     # ret = _mapbox_polygon.GetImageTileByLngLat(lngLat = lngLat, zoom = zoom, pixelsPerTile = 512)
#     # imageUrl = './uploads/land-vision-orig.jpg'
#     # cv2.imwrite(imageUrl, ret['img'])

#     ret = _mapbox_polygon.GetVectorTileByLngLat(zoom = zoom, lngLat = lngLat, tileType = 'street')
#     print ('ret', json.dumps(ret['tile'], indent = 2))

#     # _land_vision.seeLand(imageUrl)

def test_urban_tree_detection_inference():
    lngLat = [-122.033802, 37.977362]
    # ret = _mapbox_polygon.GetImageTileByLngLat(lngLat = lngLat)
    # imageUrl = './uploads/tree-detect1.png'
    # cv2.imwrite(imageUrl, ret['img'])
    # ret = _urban_trees_evaluate.GetTrees(images = [ret['img']])
    # ret = _urban_trees.GetTreesByLngLat(lngLat)
    ret = _urban_trees.GetTreesPolygons(lngLat)
    # print ('ret', len(ret['landTilePolygons']), ret)
    assert len(ret['landTilePolygons']) > 0
    for polygon in ret['landTilePolygons']:
        assert len(polygon['vertices']) == 1
        assert isinstance(polygon['posCenter'], str)
        lngLat = polygon['posCenter'].split(',')
        assert float(lngLat[0]) >= 0 and float(lngLat[1]) >= 0

    # img_dir = "./uploads/images/"
    # weights_dir = "./land_vision/urban_tree_detection/pretrained"
    # min_distance = 1
    # threshold_abs = None
    # threshold_rel = 0.2
    # max_distance = 10

    # img_list = []
    # for img_path in Path(img_dir).iterdir():
    #     if img_path.is_file() and img_path.suffix ==".png":
    #         img = cv2.imread(str(img_path))
    #         img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)  
    #         img_list.append(img_rgb)
    
    # images = np.array(img_list)

    # preprocess = eval(f'preprocess_RGB')
    # training_model, model = SFANet.build_model(images.shape[1:], preprocess_fn=preprocess)

    # weights_path = os.path.join(weights_dir,'weights.best.h5')
    # training_model.load_weights(weights_path)

    # preds = model.predict(images,verbose=True,batch_size=1)[...,0]
    # results = get_pred_locs(preds=preds,
    #     min_distance=min_distance,
    #     threshold_rel=threshold_rel,
    #     threshold_abs=threshold_abs,
    #     max_distance=max_distance)

    # assert isinstance(results['pred_locs'][0], np.ndarray)
    # assert results['pred_locs'][0].shape[1] == 2

    _mongo_mock.CleanUp()
