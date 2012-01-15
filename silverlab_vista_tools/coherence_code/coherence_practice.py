import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats

import vista_utils as tsv # Get it at: https://github.com/arokem/vista_utils
from nitime.fmri.io import time_series_from_file as load_nii 
import nitime.timeseries as ts
import nitime.viz as viz

from nitime.analysis import CorrelationAnalyzer, CoherenceAnalyzer
#Import utility functions:
from nitime.utils import percent_change
from nitime.viz import drawmatrix_channels, drawgraph_channels
from nitime.viz import drawmatrix_channels, drawgraph_channels, plot_xcorr


import subjects
reload(subjects) # In case you make changes in there while you analyze
from subjects import subjects, rois

def display_vox(tseries,vox_idx,fig=None):
    """
    Display the voxel time-series
    """
    if fig is None:
        fig = plt.figure()

    vox_tseries = ts.TimeSeries(tseries.data[vox_idx],sampling_interval=TR)

    fig = viz.plot_tseries(vox_tseries,fig)
    fig = viz.plot_tseries(ts.TimeSeries(np.mean(vox_tseries.data,0),
                                         sampling_interval=TR),
                           yerror=ts.TimeSeries(stats.sem(vox_tseries.data,0),
                                                sampling_interval=TR),fig=fig,
                           error_alpha = 0.3,ylabel='% signal change',
                           linewidth=4,
                           color='r')
    return fig

def reshapeTS(t_fix):
    segTime=60
    # Change to an array (numSess, numROIs, numTime points)
    t_fixArray=np.array(t_fix)
    #t_fixArrayTP=np.transpose(t_fixArray, (1,0,2))
    1/0
    shapeTS=t_fixArray.shape
    numRuns=shapeTS[2]/segTime
    # This returns rois x runs x TS with runs collapsed by segTime
    allROIs2=np.reshape(t_fixArray, [shapeTS[0], shapeTS[1]*numRuns, segTime])
    return allROIs

def getCorrTS(allROIS):
    fixTS=ts.TimeSeries(allROIs, sampling_interval=TR)
    # Get roi correlations
    C=CorrelationAnalyzer(fixTS)
    fig01 = drawmatrix_channels(C.corrcoef, roi_names, size=[10., 10.], color_anchor=0)
    return C    

if __name__ == "__main__":

    base_path = '/Volumes/Plata1/DorsalVentral/' # Change this to your path
    fmri_path = base_path + 'fmri/'
    session=0 # 0= donepazil, 1=placebo
    TR = 2
    # The pass band is f_lb <-> f_ub.
    # Also, see: http://imaging.mrc-cbu.cam.ac.uk/imaging/DesignEfficiency
    f_ub = 0.15
    f_lb = 0.01
    
    # The upsample factor between the Inplane and the Gray:
    # Inplane Voxels: .867 x .867 x 3.3, Functional voxels: 3 x 3 x 3.3
    up_samp = [3.4595,3.4595,1.0000]

    for subject in subjects:
        # len(subjects[subject])= number of session per subject
        # len(subjects[subject][0][1])= number of different types of runs 
        # len(subjects[subject][1][1]['fix_nii'])= number of nifti files for that session

        sess = subjects[subject][session]
        # Get ROIs
        roi_names=np.array(rois)
        ROI_files=[]
        for roi in rois:
            ROI_files.append(fmri_path+sess[0]+'/Inplane/ROIs/' +roi +'.mat')

        # Get the coordinates of the ROIs, while accounting for the
        # up-sampling:
        # 
        ROI_coords = [tsv.upsample_coords(tsv.getROIcoords(f),up_samp)
                           for f in ROI_files]
        
         # Initialize lists for each behavioral condition:
        t_fix = []
        t_left = []
        t_right = []
        nifti_path = fmri_path +sess[0] + '/%s_nifti/' % sess[0]
        # len(t_fix)= number of ROIs
        for this_fix in sess[1]['fix_nii']:
            t_fix.append(load_nii(nifti_path+this_fix, ROI_coords,TR,
                                    normalize='percent', average=True, verbose=True))
        # reshape ROI matrix
        allROIS=reshapeTS(t_fix)

        # Get roi correlations
        for i in range(allROIS.shape[1]):
            #need to load timeseries by run
            fixTS=ts.TimeSeries(allROIs, sampling_interval=TR)
        C=CorrelationAnalyzer(fixTS)
        fig01 = drawmatrix_channels(C.corrcoef, roi_names, size=[10., 10.], color_anchor=0)
        
        # Get cross correlations
        xc = C.xcorr_norm
        idx_rv1 = np.where(roi_names == 'R_V1')[0]
        idx_rv2v = np.where(roi_names == 'R_V2V')[0]
        idx_rv3v = np.where(roi_names == 'R_V3V')[0]
        idx_rv4 = np.where(roi_names == 'R_V4')[0]
        idx_rv2d= np.where(roi_names == 'R_V2D')[0]
        idx_rv3d = np.where(roi_names == 'R_V3D')[0]

        fig02 = plot_xcorr(xc,((idx_rv1, idx_rv2v),(idx_rv1, idx_rv3v)),line_labels=['rV2V', 'rV3V'])

        # Get coherence
        Coh = CoherenceAnalyzer(fixTS)

        # Get the index for the frequencies inside the ub and lb
        freq_idx = np.where((Coh.frequencies > f_lb) * (Coh.frequencies < f_ub))[0]

        # Extract coherence
        coher = np.mean(Coh.coherence[:, :, freq_idx], -1)  # Averaging on the last dimension
        fig03 = drawmatrix_channels(coher, roi_names, size=[10., 10.], color_anchor=0)

        # Focus on areas of interest
        idx = np.hstack([idx_rv1, idx_rv2v, idx_rv3v, idx_rv4, idx_rv2d, idx_rv3d ])
        idx1 = np.vstack([[idx[i]] * 6 for i in range(6)]).ravel()
        idx2 = np.hstack(6 * [idx])
        coher_specific = Coh.coherence[idx1, idx2].reshape(6, 6, Coh.frequencies.shape[0])
        coherence = np.mean(coher_specific[:, :, freq_idx], -1)  # Averaging on the last dimension
        fig04 = drawgraph_channels(coherence, roi_names[idx]) # Draw network
                                                      
