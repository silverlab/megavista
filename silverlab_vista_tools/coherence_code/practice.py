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

import subjects
reload(subjects) # In case you make changes in there while you analyze
from subjects import subjects



if __name__ == "__main__":

    base_path = '/Volumes/Plata1/DorsalVentral/' # Change this to your path
    fmri_path = base_path + 'fmri/'
    this_s='CG020611'
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
        # Just do the placebo session, 0=donepazil, 1=placebo
        sess = subjects[subject][1]
        # Loop over sessions (donepezil/placebo):
        roi_names=['R_V1', 'R_V2V', 'R_V3V', 'R_V2D', 'R_V3D','R_V4','R_V7', 'R_IPS1', 'R_IPS2', 'L_V1', 'L_V2',  'L_V3',  'L_V4', ]
        roi_names=np.array(roi_names)
        ROI_files=[fmri_path+sess[0]+'/Inplane/ROIs/R_V1.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/R_V2V.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/R_V3V.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/R_V2D.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/R_V3D.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/R_V4.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/R_V7.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/R_IPS1.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/R_IPS2.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/L_V1.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/L_V2.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/L_V3.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/L_V4.mat']

        nifti_path = fmri_path +sess[0] + '/%s_nifti/' % sess[0]

        # Get the coordinates of the ROIs, while accounting for the
        # up-sampling:
        # 
        ROI_coords = [tsv.upsample_coords(tsv.getROIcoords(f),up_samp)
                           for f in ROI_files]
         # Initialize lists for each behavioral condition:
        t_fix = []
        t_left = []
        t_right = []

        # len(t_fix)= number of ROIs
        for this_fix in sess[1]['fix_nii']:
            t_fix.append(load_nii(nifti_path+this_fix, ROI_coords,TR,
                                    normalize='percent', average=True, verbose=True))
        # Change to an array (numSess, numROIs, numTime points)
        t_fixArray=np.array(t_fix)
        # Swap ROI and session dimension
        t_fixArray=np.transpose(t_fixArray, (1,0,2))
        shape=t_fixArray.shape
        allROIs=np.reshape(t_fixArray, [shape[0], shape[1]*shape[2]])
        fixTS=ts.TimeSeries(allROIs, sampling_interval=TR)

        C=CorrelationAnalyzer(fixTS)
        fig01 = drawmatrix_channels(C.corrcoef, roi_names, size=[10., 10.], color_anchor=0)
      
