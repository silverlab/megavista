#!/usr/bin/env python
# encoding: utf-8
"""
rd_make_mp_roi_nifti.py

Created by Rachel on 2012-05-04.
"""

import os
import glob
import numpy as np
import scipy.io as sio
import util

def main():
    scanner = '7T'
    subject = 9
    hemi = 2
    prop = 0.2
    varthresh = 0
    group_names = ['M','P']
    example_epi_name = 'epi01_fix_fsldc.nii.gz'

    # file i/o
    sdirs = sio.loadmat('/Volumes/Plata1/LGN/Group_Analyses/subjectDirs_20121103.mat')

    if scanner=='3T':
        subject_dirs = sdirs['subjectDirs3T']
    elif scanner=='7T':
        subject_dirs = sdirs['subjectDirs7T']

    session_dir = '/Volumes/Plata1/LGN/Scans/{0}/{1}/{2}'.format(
        scanner, subject_dirs[subject,0][0], subject_dirs[subject,1][0])
    nifti_dir = '{0}/{1}_nifti/'.format(session_dir, subject_dirs[subject,1][0])
    out_dir = '{0}/Masks/'.format(session_dir)

    print session_dir

    # analysis file i/o
    analysis_dir = '{0}/ROIAnalysis/{1}/'.format(session_dir, subject_dirs[subject,2][0])
    analysis_file_base = 'lgnROI{}_comVoxGroupCoords_'.format(hemi)
    analysis_extension = 'betaM-P_prop{}_varThresh{:0^3}'.format(
        int(prop*100), int(varthresh*1000))
    data_path = glob.glob(analysis_dir + analysis_file_base + analysis_extension + '*')[0]

    # import lgn data
    data = sio.loadmat(data_path)
    X = data['voxCoords']
    Y = data['voxGroups']
    Y = np.squeeze(Y)

    # example epi to be used in afni 3dUndump
    example_epi = nifti_dir + example_epi_name

    print 'Example epi:', example_epi
    
    # loop over M and P voxel groups
    for group in np.unique(Y):

        # get the coordinates for the ROI
        # subtract 1 from mrVista coords, since afni uses 0 indexing
        roi_coords = X[Y==group]-1

        # save this to a text file for AFNI
        roi_name = analysis_file_base + analysis_extension + '_' + group_names[group-1] + 'roi'
        fout_coords = out_dir + roi_name + '_coords.txt'
        np.savetxt(fout_coords,roi_coords)

        # run afni 3dUndump command to make this into an ROI
        fout_nii = out_dir + roi_name + '_orig.nii'
        command = "3dUndump -prefix %s -master %s %s" %(fout_nii,
                                                        example_epi,
                                                        fout_coords)
        util.remove_previous_files(fout_nii) #remove file if it exists
        print command
        os.system(command)

        # Looks like this is R/L flipped? Flipping to normal
        print 'Flipping ROI'
        fout_nii_new = out_dir + roi_name + '_flip.nii'
        command = "3dresample -orient LPI -prefix %s -inset %s" %(fout_nii_new,
                                                                  fout_nii)
        util.remove_previous_files(fout_nii_new)
        os.system(command)

        # we don't need the orig file anymore, it is L-R reversed
        # util.remove_previous_files(fout_nii)


if __name__ == '__main__':
	main()


