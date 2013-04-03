#!/usr/bin/env python
# encoding: utf-8
"""
rd_make_mrvista_roi_nifti.py

Now you have some ROIs in mrVista's Inplane space.  
Here, you'll take those coordinates, transform them, and use them to
make a volume ROI (mask) in nifti format.

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
def main():
    #inputs
    # scanner = sys.argv[1]
    # subject = sys.argv[2]
    # rois = ['LLGN_ecc0','LLGN_ecc14','LLGN_polar0','LLGN_polar5',
        # 'RLGN_ecc2','RLGN_ecc9','RLGN_polar2','RLGN_polar4']
    rois = ['LV1_ecc0-2', 'LV1_ecc10-18', 'LV1_polar602-026', 'LV1_polar474-526',
        'RV1_ecc1-3', 'RV1_ecc7-11', 'RV1_polar174-226', 'RV1_polar374-426']
    # rois = ['RV1','LV1','RV2v','LV2v','RV2d','LV2d','RV3v','LV3v','RV3d','LV3d']

    combine_early_vis_rois = False

    #paths
    # sdirs = sio.loadmat('/Volumes/Plata1/LGN/Group_Analyses/subjectDirs_20121103.mat')

    # if scanner=='3T':
    #     subject_dirs = sdirs['subjectDirs3T']
    # elif scanner=='7T':
    #     subject_dirs = sdirs['subjectDirs7T']
    # 
    # data_dir = '/Volumes/Plata1/LGN/Scans/{0}/{1}/{2}/'.format(
    #     scanner, subject_dirs[subject,0][0], subject_dirs[subject,1][0])
    # nifti_dir = '{0}/{1}_nifti/'.format(data_dir, subject_dirs[subject,1][0])
    # roi_dir = '{0}/Inplane/ROIs/'.format(data_dir)
    # out_dir = '{0}/Masks/'.format(data_dir)

    data_dir = '/Volumes/Plata1/LGN/Scans/7T/JN_20120808_Session/JN_20120808_fslDC/'
    nifti_dir = os.path.join(data_dir,'JN_20120808_fslDC_nifti/')
    roi_dir = os.path.join(data_dir,'Inplane/ROIs/')
    out_dir = os.path.join(data_dir,'Masks/')

    print data_dir

    #constants
    up_samp = [1.0000,1.0000,1.0000] #upsample factor from EPI to GEM
    # up_samp = [2.5606,2.5606,1.0000]
    #usually epi: 2.220 x 2.220 x 2.300; gem: 0.867x0.867x2.300

    example_epi = nifti_dir + 'epi01_fix_fsldc.nii.gz'

    #Loop over ROIs
    for roi in rois:

        roi_file = roi_dir + roi + '.mat'

        #get the coordinates for the ROI, accounting for upsampling
        # upsample_coords takes into account 1 vs. 0-based indexing
        roi_coords = tsv.upsample_coords(tsv.getROIcoords(roi_file),up_samp)

        #save this to a text file for AFNI
        fout_coords = out_dir + roi + '_coords.txt'
        np.savetxt(fout_coords,roi_coords.transpose())

        #run afni 3dUndump command to make this into an ROI
        fout_nii = out_dir + roi + '_orig.nii'
        command = "3dUndump -prefix %s -master %s %s" %(fout_nii,
                                                        example_epi,
                                                        fout_coords)
        util.remove_previous_files(fout_nii) #remove file if it exists
        print command
        os.system(command)

        #Looks like this is R/L flipped? Flipping to normal
        print 'Flipping ROI'
        fout_nii_new = out_dir +  roi + '.nii'
        command = "3dresample -orient LPI -prefix %s -inset %s" %(fout_nii_new,
                                                                  fout_nii)
        util.remove_previous_files(fout_nii_new)
        os.system(command)

        # we don't need the orig file anymore, it is L-R reversed
        # util.remove_previous_files(fout_nii)


    #Sum together ROI pairs to get a single V1,V2, and V3
    if combine_early_vis_rois:
        print 'Making large *all* ROIs'
        roi_final = ['V1','V2','V3']
        for roi in roi_final:
            fout = out_dir + '_all' + roi + '.nii.gz'
            fout_d = out_dir + '_all' + roi + 'd.nii.gz'
            fout_v = out_dirout_dir + '_all' + roi + 'v.nii.gz'

            if roi == 'V1':
                #note: ispositive is used to deal with potential overlap
                command = "3dcalc -a %s%s_L%s.nii.gz -b %s%s_R%s.nii.gz -expr 'ispositive(a+b)' -prefix %s" %(out_dir,sub,roi,out_dir,sub,roi,fout)

                util.remove_previous_files(fout)
                os.system(command)

            else:
                command = "3dcalc -a %s%s_L%sd.nii.gz -b %s%s_R%sd.nii.gz -c  %s%s_L%sv.nii.gz -d %s%s_R%sv.nii.gz -expr 'ispositive(a+b+c+d)' -prefix %s" %(out_dir,sub,roi,out_dir,sub,roi,out_dir,sub,roi,out_dir,sub,roi,fout)
                util.remove_previous_files(fout)
                os.system(command)

                command = "3dcalc -a %s%s_L%sv.nii.gz -b %s%s_R%sv.nii.gz -expr 'ispositive(a+b)' -prefix %s" %(out_dir,sub,roi,out_dir,sub,roi,fout_v)
                util.remove_previous_files(fout_v)
                os.system(command)
            
                command = "3dcalc -a %s%s_L%sd.nii.gz -b %s%s_R%sd.nii.gz -expr 'ispositive(a+b)' -prefix %s" %(out_dir,sub,roi,out_dir,sub,roi,fout_d)
                util.remove_previous_files(fout_d)
                os.system(command)

## Main script
if __name__ == "__main__":
    main()
    
    
    
