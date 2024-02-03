""" Compute metrics on test set. """
import numpy as np
import argparse
import os
import yaml
from land_vision.urban_tree_detection.evaluate import get_pred_locs, make_figure_with_pred
import land_vision.urban_tree_detection.models.SFANet as SFANet
from land_vision.urban_tree_detection.preprocess import preprocess_RGB
from pathlib import Path
import cv2
import matplotlib 
matplotlib.use('Agg')
import matplotlib.pyplot as plt

def main():
    """
    runs the inference and store the predicted tree locations and plots them
    To run it: 
    python -m land_vision.urban_tree_detection.inference uploads/images/  \
           land_vision/urban_tree_detection/pretrained/ land_vision/urban_tree_detection/log/ 
    """
    parser = argparse.ArgumentParser()

    parser.add_argument('data', help='path to png naip image directory')
    parser.add_argument('weights', help='path to pretrained weghts directory')
    parser.add_argument('log', help='path to log directory')
    parser.add_argument('--max_distance', type=float, default=10, help='max distance from gt to pred tree (in pixels)')

    args = parser.parse_args()

    params_path = os.path.join(args.log,'params.yaml')
    if os.path.exists(params_path):
        with open(params_path,'r') as f:
            params = yaml.safe_load(f)
            mode = params['mode']
            min_distance = params['min_distance']
            threshold_abs = params['threshold_abs'] if mode == 'abs' else None
            threshold_rel = params['threshold_rel'] if mode == 'rel' else None
    else:
        print(f'warning: params.yaml missing -- using default params')
        min_distance = 1
        threshold_abs = None
        threshold_rel = 0.2
    
    img_list = []
    for img_path in Path(args.data).iterdir():
        if img_path.is_file() and img_path.suffix ==".png":
            img = cv2.imread(str(img_path))
            img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)  
            img_list.append(img_rgb)
    
    images = np.array(img_list)

    bands = 'RGB'  
    
    preprocess = eval(f'preprocess_{bands}')
    training_model, model = SFANet.build_model(
        images.shape[1:],
        preprocess_fn=preprocess)

    weights_path = os.path.join(args.weights, 'weights.best.h5')
    training_model.load_weights(weights_path)

    print('----- getting predictions from trained model -----')
    preds = model.predict(images,verbose=True,batch_size=1)[...,0]
    print('----- getting predicted locations -----')
    results = get_pred_locs(preds=preds,
        min_distance=min_distance,
        threshold_rel=threshold_rel,
        threshold_abs=threshold_abs,
        max_distance=args.max_distance)
    
    print("len of results", len(results['pred_locs']))

    with open(os.path.join(args.log,'loc_results2.txt'),'w') as f:
        f.write('predicted locations: '+str(results['pred_locs'])+'\n')

    print('------- results for: ' + args.log + ' ---------')

    fig = make_figure_with_pred(images,results, num_cols=1)
    #plt.show()
    fig.savefig(os.path.join(args.log,'figures_with_locs.pdf'))

if __name__ == '__main__':
    main()
