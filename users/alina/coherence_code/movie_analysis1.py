"""

Basic analysis of movie data to get a sense of voxel-by-voxel reliability.

"""

import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats

import vista_utils as tsv # Get it at: https://github.com/arokem/vista_utils
from nitime.fmri.io import time_series_from_file as load_nii 
import nitime.timeseries as ts
import nitime.viz as viz

import subjects
reload(subjects) # In case you make changes in there while you analyze
from subjects import subjects

from nitime.analysis import CorrelationAnalyzer, CoherenceAnalyzer
#Import utility functions:
from nitime.utils import percent_change
from nitime.viz import drawmatrix_channels, drawgraph_channels, plot_xcorr

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


if __name__ == "__main__":

    # Where's the data? 
    base_path = '/Volumes/Plata1/DorsalVentral/' # Change this to your path
    fmri_path = base_path + 'fmri/'
    TR = 2
    # The pass band is f_lb <-> f_ub.
    # Also, see: http://imaging.mrc-cbu.cam.ac.uk/imaging/DesignEfficiency
    f_ub = 0.15
    f_lb = 0.01
    
    # The upsample factor between the Inplane and the Gray:
    # Inplane Voxels: .867 x .867 x 3.3, Functional voxels: 3 x 3 x 3.3
    up_samp = [3.4595,3.4595,1.0000]
    

    # Loop over subjects: 
    for subject in subjects:
        sess = subjects[subject]
        # Loop over sessions (donepezil/placebo):
        for this_s in sess:
            ROI_files=[fmri_path+this_s[0]+'/Inplane/ROIs/R_V1.mat',
                       fmri_path+this_s[0]+'/Inplane/ROIs/L_V1.mat']

            nifti_path = fmri_path + this_s[0] + '/%s_nifti/'%this_s[0]

            # Get the coordinates of the ROIs, while accounting for the
            # up-sampling:
            # 
            ROI_coords = [tsv.upsample_coords(tsv.getROIcoords(f),up_samp)
                               for f in ROI_files]

            # Initialize lists for each behavioral condition:
            t_fix = []
            t_left = []
            t_right = []

            for this_fix in this_s[1]['fix_nii']:
                # Read data from each ROI, from each voxel. If you want to
                # average across voxels, set the "average" kwarg to True:

                # what's this filter? Does it average?
                t_fix.append(load_nii(nifti_path+this_fix,
                                      ROI_coords,
                                      TR,
                                      normalize='percent',
                                      filter=dict(method='iir',lb=f_lb,
                                                  ub=f_ub,
                                                  filt_order=50),
                                      verbose=True))
            for this_left in this_s[1]['left_nii']:
                t_left.append(load_nii(nifti_path+this_left,
                                       ROI_coords,
                                       TR,
                                       normalize='percent',
                                       filter=dict(method='iir',lb=f_lb,
                                                   ub=f_ub,
                                                   filt_order=50),
                                       verbose=True))

            for this_right in this_s[1]['right_nii']:
                t_right.append(load_nii(nifti_path+this_right,
                                        ROI_coords,
                                        TR,
                                        normalize='percent',
                                        filter=dict(method='iir',lb=f_lb,
                                                    ub=f_ub,
                                                    filt_order=50),
                                        verbose=True))

            # Done reading in all the data from disk, now do something with it: 

            TR_trial = 30 #TRs/trial = 30
            n_left = t_left[0][0].shape[-1]/TR_trial
            n_right = t_right[0][0].shape[-1]/TR_trial
            n_fix = t_fix[0][0].shape[-1]/TR_trial
            hemis = ['R','L']
            for h_idx,hemi in enumerate(hemis):
                this_left = t_left[h_idx][0]
                this_right = t_right[h_idx][0]
                this_fix = t_fix[h_idx][0]
                n_vox = this_left.data.shape[0]

                # Reshaping and initializing another TimeSeries: 
                left = ts.TimeSeries(this_left.data.reshape((n_vox,
                                                             n_left,
                                                             TR_trial)),
                                                        sampling_interval=TR)

                right = ts.TimeSeries(this_right.data.reshape((n_vox,
                                                             n_right,
                                                             TR_trial)),
                                                        sampling_interval=TR)

                fix = ts.TimeSeries(this_fix.data.reshape((n_vox,
                                                             n_fix,
                                                             TR_trial)),
                                                        sampling_interval=TR)

                # Some random voxel:
                fig1 = display_vox(left,9)
                fig2 = display_vox(right,9)
                1/0
               
