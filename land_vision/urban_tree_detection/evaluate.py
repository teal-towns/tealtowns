import cv2
import numpy as np
import os
from skimage.feature import peak_local_max
from matplotlib import pyplot as plt
import tqdm

from land_vision.urban_tree_detection.models import SFANet as SFANet
from land_vision.urban_tree_detection.preprocess import preprocess_RGB

def GetTrees(imagePaths: list = [], images = [], weightsDir = "./land_vision/urban_tree_detection/pretrained"):
    ret = { 'pixels': [] }
    if len(images) == 0:
        images = []
        for imagePath in imagePaths:
            image = cv2.imread(imagePath)
            imageRgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            images.append(imageRgb)
    else:
        for index, image in enumerate(images):
            images[index] = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    images = np.array(images)

    preprocess = eval(f'preprocess_RGB')
    trainingModel, model = SFANet.build_model(images.shape[1:], preprocess_fn=preprocess)
    weightsPath = os.path.join(weightsDir,'weights.best.h5')
    trainingModel.load_weights(weightsPath)

    preds = model.predict(images,verbose=True,batch_size=1)[...,0]
    results = get_pred_locs(preds=preds)
    ret['pixels'] = results['pred_locs'][0]

    return ret

def get_pred_locs(preds, min_distance = 1, threshold_rel = 0.2, threshold_abs = None, max_distance = 10):
    """ predict x,y locations of predicted points.
        Arguments:
            preds: predicted confidence maps [N,H,W]
            min_distance: minimum distance between detections
            threshold_rel: relative threshold for local peak finding (None to disable)
            threshold_abs: absolute threshold for local peak finding (None to disable)
            max_distance: maximum distance from detection to gt point 
        Returns:
            Result dictionary containin pred_locs: x,y locations of predicted points
    """

    all_pred_locs = []   
    for pred in preds:
        pred_indices = peak_local_max(pred,min_distance=min_distance,threshold_abs=threshold_abs,threshold_rel=threshold_rel)
        pred_locs = []
        for y,x in pred_indices:
            pred_locs.append([x,y])

        pred_locs = np.array(pred_locs)
        all_pred_locs.append(pred_locs)


    results = {
        'pred_locs': all_pred_locs
    }

    return results



def make_figure_with_pred(images,results,num_cols=5):
    """ only superimpose predicted points on the image"""
    num_rows = len(images)//num_cols+1
    fig,ax = plt.subplots(num_rows,num_cols,figsize=(8.5,11),tight_layout=True)
    for a in ax.flatten(): 
        a.axis('off')
    pred_locs = results['pred_locs']
    for a,im,loc in zip(ax.flatten(),images,pred_locs):
        a.imshow(im)
        if len(loc)>0:
            if len(loc.shape)==1: loc = loc[None,:]
            a.plot(loc[:,0],loc[:,1],'y+')
        
    return fig