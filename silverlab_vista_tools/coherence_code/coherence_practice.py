import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats
import pickle 
import datetime

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
    # TR=2 seconds, 30 TRs in one movie
    segTime=60
    # Change to an array (numSess, numROIs, numTime points)
    t_fixArray=np.array(t_fix)
    t_fixArrayTP=np.transpose(t_fixArray, (1,0,2))
    shapeTS=t_fixArrayTP.shape
    numRuns=shapeTS[2]/segTime
    # This returns rois x runs x TS with runs collapsed by segTime
    allROIS=np.reshape(t_fixArrayTP, [shapeTS[0], shapeTS[1]*numRuns, segTime])
    return allROIS
  

if __name__ == "__main__":
    
    
    base_path = '/Volumes/Plata1/DorsalVentral/' # Change this to your path
    fmri_path = base_path + 'fmri/'
    session=0 # 0= donepazil, 1=placebo
    TR = 2

    # save filename
    date=str(datetime.date.today())
    saveFile=base_path+ 'fmri/Results/' + 'All5Subs'+ date + '.pck'

    # The pass band is f_lb <-> f_ub.
    # Also, see: http://imaging.mrc-cbu.cam.ac.uk/imaging/DesignEfficiency
    f_ub = 0.15
    f_lb = 0.01

    NFFT=32 # 1/64= freq limit lower, .25 hertz is upper limit (1/2 of sampling rate) Nyquist freq
    n_overlap=16
    
    # The upsample factor between the Inplane and the Gray:
    # Inplane Voxels: .867 x .867 x 3.3, Functional voxels: 3 x 3 x 3.3
    up_samp = [3.4595,3.4595,1.0000]

    # set up dictionaries to store results
    corr_all=dict()
    coh_all = dict()
    

    for subject in subjects:
        # len(subjects[subject])= number of session per subject
        # len(subjects[subject][0][1])= number of different types of runs 
        # len(subjects[subject][1][1]['fix_nii'])= number of nifti files for that session

        # Close any opened plots
        plt.close('all')
        
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

        # Plot the mean of the TS over SD (SNR) for each ROI
        # len(t_fix)= number of ROIs
        for this_fix in sess[1]['fix_nii']:
            t_fix.append(load_nii(nifti_path+this_fix, ROI_coords,TR,
                                    normalize='percent', average=True, verbose=True))

        for this_fix in sess[1]['right_nii']:
            t_fix.append(load_nii(nifti_path+this_fix, ROI_coords,TR,
                                    normalize='percent', average=True, verbose=True))

        for this_fix in sess[1]['left_nii']:
            t_fix.append(load_nii(nifti_path+this_fix, ROI_coords,TR,
                                    normalize='percent', average=True, verbose=True))    
         # reshape ROI matrix
        allROIS=reshapeTS(t_fix)
        numRuns=allROIS.shape[1]

        corr_all[subject] = np.zeros((numRuns,len(rois),len(rois))) * np.nan
        coh_all[subject] = np.zeros((numRuns,len(rois),len(rois))) * np.nan
       
        # Get roi correlations and coherence
        for run in range(allROIS.shape[1]):
            #need to load timeseries by run
            fixTS=ts.TimeSeries(allROIS[:,run,:], sampling_interval=TR)
            fixTS.metadata['roi'] = roi_names
           
            # Get plot and correlations
            C=CorrelationAnalyzer(fixTS)
            fig01 = drawmatrix_channels(C.corrcoef, roi_names, size=[10., 10.], color_anchor=0,  title='Correlation Results Run %i' % run)
            plt.show()
            # Save correlation
            corr_all[subject][run]=C.corrcoef

            # Get coherence
            Coh = CoherenceAnalyzer(fixTS)
   
            Coh.method['NFFT'] = NFFT
            Coh.method['n_overlap']=n_overlap

            # Get the index for the frequencies inside the ub and lb
            freq_idx = np.where((Coh.frequencies > f_lb) * (Coh.frequencies < f_ub))[0]
            
            # Extract coherence
            # Coher[0]= correlations for first ROI in list with others
            coher = np.mean(Coh.coherence[:, :, freq_idx], -1)  # Averaging on the last dimension
            fig03 = drawmatrix_channels(coher, roi_names, size=[10., 10.], color_anchor=0, title='Coherence Results Run %i' % run)
            # Save coherence (coher is the average of the coherence over the specified frequency)
            coh_all[subject][run]=coher

    file=open(saveFile, 'w') # write mode
    # First file loaded is coherence
    pickle.dump(coh_all, file)
    # Second file loaded is correlation
    pickle.dump(corr_all, file)
    # Save roi names
    pickle.dump(roi_names, file)
    file.close()
    print 'Saving subject coherence and correlation dictionaries.'
            
