import numpy as np

from skimage.feature import peak_local_max
from matplotlib import pyplot as plt

import tqdm



def predict(preds, min_distance, threshold_rel, threshold_abs, max_distance):
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