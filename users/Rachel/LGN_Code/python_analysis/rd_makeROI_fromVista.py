"""
Now you have some ROIs in mrVista's Inplane space.  
Here, you'll take those coordinates, transform them, and use them to
make a volume ROI (mask) in nifti format.

Following this, should run a GLM on the localizer data and use that to restrict
the ROIs.

Based on CG's makeROI_fromVista.py
which in turn was in part based off of Ariel's movie_analysis1.py (find in example_scripts/)

Rachel Denison
2012 May 03
"""

## Import libraries
import sys
import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats
import scipy.io as sio
import os

import vista_utils as tsv # Get it at: https://github.com/arokem/vista_utils

import util
reload(util) #in case you make changes

## Definitions



## Main script
if __name__ == "__main__":

    #inputs
    scanner = sys.argv[1]
    subject = sys.argv[2]
    rois = ['ROI101','ROI201']
    # rois = ['RV1','LV1','RV2v','LV2v','RV2d','LV2d','RV3v','LV3v','RV3d','LV3d']

    #paths
    sdirs = sio.loadmat('/Volumes/Plata1/LGN/Group_Analyses/subjectDirs.mat')

    if scanner=='3T':
        subject_dirs = sdirs['subjectDirs3T']
    elif scanner=='7T':
        subject_dirs = sdirs['subjectDirs7T']
    
    data_dir = '/Volumes/Plata1/LGN/Scans/{0}/{1}/{2}/'.format(
        scanner, subject_dirs[subject,0][0], subject_dirs[subject,1][0])
    nifti_dir = '{0}/{1}_nifti/'.format(data_dir, subject_dirs[subject,1][0])
    roiDir = '{0}/Inplane/ROIs/'.format(data_dir)
    outDir = '{0}/Masks/'.format(data_dir)

    print data_dir

    #constants
    up_samp = [2.5606,2.5606,1.0000] #upsample factor from GEM to EPI
    #usually epi: 2.220 x 2.220 x 2.300; gem: 0.867x0.867x2.300

    EPIfname_example = dataDir + 'epi01_mcf.nii.gz'

    #Loop over ROIs
    for roi in rois:

        ROIfile = roiDir + roi + '.mat'

        #get the coordinates for the ROI, accounting for upsampling
        ROI_coords = tsv.upsample_coords(tsv.getROIcoords(ROIfile),up_samp)

        #save this to a text file for AFNI
        fout_coords = outDir + sub + '_' + roi + '_coords.txt'
        np.savetxt(fout_coords,ROI_coords.transpose())

        #run afni 3dUndump command to make this into an ROI
        fout_nii = outDir + sub + '_'+ roi + '_orig.nii'
        command = "3dUndump -prefix %s -master %s %s" %(fout_nii,
                                                        EPIfname_example,
                                                        fout_coords)
        util.remove_previous_files(fout_nii) #remove file if it exists
        print command
        os.system(command)

        #Looks like this is R/L flipped? Flipping to normal
        print 'Flipping ROI'
        fout_nii_new = outDir + sub + '_' +  roi + '_flip.nii'
        command = "3dresample -orient LPI -prefix %s -inset %s" %(fout_nii_new,
                                                                  fout_nii)
        util.remove_previous_files(fout_nii_new)
        os.system(command)


    #Sum together ROI pairs to get a single V1,V2, and V3
    print 'Making large *all* ROIs'
    roi_final = ['V1','V2','V3']
    for roi in roi_final:
        fout = outDir + sub + '_all' + roi + '_flip.nii'
        fout_d = outDir + sub + '_all' + roi + 'd_flip.nii'
        fout_v = outDir + sub + '_all' + roi + 'v_flip.nii'

        if roi == 'V1':
            #note: ispositive is used to deal with potential overlap
            command = "3dcalc -a %s%s_L%s_flip.nii -b %s%s_R%s_flip.nii -expr 'ispositive(a+b)' -prefix %s" %(outDir,sub,roi,outDir,sub,roi,fout)

            util.remove_previous_files(fout)
            os.system(command)

        else:
            command = "3dcalc -a %s%s_L%sd_flip.nii -b %s%s_R%sd_flip.nii -c  %s%s_L%sv_flip.nii -d %s%s_R%sv_flip.nii -expr 'ispositive(a+b+c+d)' -prefix %s" %(outDir,sub,roi,outDir,sub,roi,outDir,sub,roi,outDir,sub,roi,fout)
            util.remove_previous_files(fout)
            os.system(command)

            command = "3dcalc -a %s%s_L%sv_flip.nii -b %s%s_R%sv_flip.nii -expr 'ispositive(a+b)' -prefix %s" %(outDir,sub,roi,outDir,sub,roi,fout_v)
            util.remove_previous_files(fout_v)
            os.system(command)
            
            command = "3dcalc -a %s%s_L%sd_flip.nii -b %s%s_R%sd_flip.nii -expr 'ispositive(a+b)' -prefix %s" %(outDir,sub,roi,outDir,sub,roi,fout_d)
            util.remove_previous_files(fout_d)
            os.system(command)

            
