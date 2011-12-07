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
    this_s='CG011611'
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
        ROI_files=[fmri_path+sess[0]+'/Inplane/ROIs/R_V1.mat',
                   fmri_path+sess[0]+'/Inplane/ROIs/L_V1.mat']

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

        roi1=t_fixArray[0]
        roi2=t_fixArray[1]

        roi1All=[]
        for numROIs in roi1:
            roi1All+=numROIs

        roi1list=roi1.tolist()    
        roiAll=roi1list[0]+roi1list[1]+roi1list[2]    
    
            
