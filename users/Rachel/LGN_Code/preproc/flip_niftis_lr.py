#!/usr/bin/env python
# encoding: utf-8
"""
flip_niftis_lr.py

Created by Rachel Denison on 2013-03-12.
"""

import sys
import os
import glob


def get_file_names():
    files = glob.glob('*.nii.gz')
    files_lr = []
    for file in files:
        a = os.path.splitext(file)
        b = os.path.splitext(a[0])
        name = b[0]
        files_lr.append('{}_lr.nii.gz'.format(name))
    return files, files_lr
        

def check_file_orientations(files):
    for file in files:
        print file
        os.system('mri_info --orientation {}'.format(file))


def reorient(files, files_lr, new_orientation):
    for file, file_lr in zip(files, files_lr):
        os.system('mri_convert --in_orientation {} {} {}'.format(
            new_orientation, file, file_lr))
        

if __name__ == '__main__':
	# #The full path to the nifti files and the new orientation can be command-line arguments: 
	#     nifti_dir = sys.argv[1]
	#     new_orientation = sys.argv[2]

    nifti_dir = '/Volumes/Plata1/LGN/Scans/7T/MN_20120806_Session/MN_20120806_recon2_flipLR/MN_20120806_recon2_nifti'
    new_orientation = 'LAS'

    # Remove trailing backslash if it has been included in the directory path
    if nifti_dir[-1]=='/': 
        nifti_dir=nifti_dir[:-1]

    # Switch to nifti directory:
    os.chdir(nifti_dir)
    # Tell us where we are
    print os.path.realpath(os.path.curdir)

    files, files_lr = get_file_names()
    check_file_orientations(files)

    print '\nNew orientation is set to {}'.format(new_orientation)
    raw_input("Press Enter to accept...")

    reorient(files, files_lr, new_orientation)

