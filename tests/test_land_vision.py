
import cv2
import numpy as np
import os
from pathlib import Path
from land_vision.urban_tree_detection.evaluate import get_pred_locs
from land_vision.urban_tree_detection.models import SFANet as SFANet
from land_vision.urban_tree_detection.preprocess import preprocess_RGB


# from mapbox import mapbox_polygon as _mapbox_polygon
# from land_vision import land_vision as _land_vision

# def test_seeLand():
#     imageUrl = 'https://ultralytics.com/images/bus.jpg'
#     imageUrl = './uploads/bus.jpg'

#     lngLat = [-122.033802, 37.977362]
#     zoom = 16
#     # zoom = 17
#     # ret = _mapbox_polygon.GetImageTileByLngLat(lngLat, zoom = zoom, pixelsPerTile = 512)
#     # imageUrl = './uploads/land-vision-orig.jpg'
#     # cv2.imwrite(imageUrl, ret['img'])

#     ret = _mapbox_polygon.GetVectorTileByLngLat(lngLat, zoom = zoom, tileType = 'street')
#     print ('ret', json.dumps(ret['tile'], indent = 2))

#     # _land_vision.seeLand(imageUrl)

def test_urban_tree_detection_inference():
    img_dir = "./uploads/images/"
    weights_dir = "./land_vision/urban_tree_detection/pretrained"
    min_distance = 1
    threshold_abs = None
    threshold_rel = 0.2
    max_distance = 10

    img_list = []
    for img_path in Path(img_dir).iterdir():
        if img_path.is_file() and img_path.suffix ==".png":
            img = cv2.imread(str(img_path))
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)  
            img_list.append(img_rgb)
    
    images = np.array(img_list)
    
    preprocess = eval(f'preprocess_RGB')
    training_model, model = SFANet.build_model(
        images.shape[1:],
        preprocess_fn=preprocess)

    weights_path = os.path.join(weights_dir,'weights.best.h5')
    training_model.load_weights(weights_path)

    preds = model.predict(images,verbose=True,batch_size=1)[...,0]
    results = get_pred_locs(preds=preds,
        min_distance=min_distance,
        threshold_rel=threshold_rel,
        threshold_abs=threshold_abs,
        max_distance=max_distance)

    assert isinstance(results['pred_locs'][0], np.ndarray)
    assert results['pred_locs'][0].shape[1] == 2

    

