#!/usr/bin/env python
# encoding: utf-8
"""
t1_div_pd.py

t1_div_pd path-to-segmentation-files subjectID
 
Normalizes a T1 mprage by a PD scan collected in the same session.
Assumes no motion between scans.

Creates brain mask from PD scan
Creates T1/PD scan
Masks PD, T1, and T1/PD scan

Created by Rachel on 2012-09-12.
"""

import sys
import os

if __name__ == '__main__':
    
    #The full path to the session files is a command-line argument: 
    sess_dir = sys.argv[1]
    if sess_dir[-1]=='/': #If a trailing backslash has been input
        sess_dir=sess_dir[:-1]
    sess_name = os.path.split(sess_dir)[1]
    #switch to session directory:
    os.chdir(sess_dir)

    # The subject ID (usually initials) is a second command-line argument
    subjectID = sys.argv[2]

    # Tell us where we are
    print os.path.realpath(os.path.curdir)

    #Set up some variables
    nifti_ext = 'nii.gz'
    pd_name = subjectID + '_PD'
    t1_name = subjectID + '_T1'
    mask_name = subjectID + '_brainmask'
    t1norm_name = subjectID + '_t1_div_pd'

    # List of OS commands
    commands = [
        # Divide the T1 scan by the PD scan
        'fslmaths {0}.{3} -mul 100 -div {1}.{3} {2}.{3}'.format(t1_name, pd_name, t1norm_name, nifti_ext),
        
        # Brain extract the PD scan using FSL
        'bet {0}.{1} {0}_masked.{1} -f 0.5 -g 0 -m'.format(pd_name, nifti_ext),

        # rename the mask file
        'mv *_mask.{1} {0}.{1}'.format(mask_name, nifti_ext),
        # Mask the normalized scan
        'fslmaths {0}.{2} -mul {1}.{2} {0}_masked.{2}'.format(t1norm_name, mask_name, nifti_ext),
    
        # Mask the T1 scan (just for fun)
        'fslmaths {0}.{2} -mul {1}.{2} {0}_masked.{2}'.format(t1_name, mask_name, nifti_ext)]

    # Print and do commands
    for command in commands:
        print command
        out = os.system(command)
        if out!=0:
            print ('command failed')
            break

    
    