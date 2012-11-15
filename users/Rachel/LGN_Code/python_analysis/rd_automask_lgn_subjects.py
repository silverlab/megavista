#!/usr/bin/env python
# encoding: utf-8
"""
rd_automask_lgn_subjects.py

Created by Rachel on 2012-05-08.
Copyright (c) 2012 __MyCompanyName__. All rights reserved.
"""

import os
import scipy.io as sio

def main():
    scanner = '7T'
    subject = 9

    # file i/o
    sdirs = sio.loadmat('/Volumes/Plata1/LGN/Group_Analyses/subjectDirs_20121103.mat')

    if scanner=='3T':
        subject_dirs = sdirs['subjectDirs3T']
    elif scanner=='7T':
        subject_dirs = sdirs['subjectDirs7T']

    session_dir = '/Volumes/Plata1/LGN/Scans/{0}/{1}/{2}'.format(
        scanner, subject_dirs[subject,0][0], subject_dirs[subject,1][0])
    nifti_dir = '{0}/{1}_nifti/'.format(session_dir, subject_dirs[subject,1][0])
    out_file = '{0}/Masks/automask.nii.gz'.format(session_dir)

    example_epi = nifti_dir + 'epi01_fix_fsldc.nii.gz'
    
    command = '3dAutomask -prefix {0} {1}'.format(out_file, example_epi)
    print command
    os.system(command)


if __name__ == '__main__':
    main()

