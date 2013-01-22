#!/usr/bin/env python
# encoding: utf-8
"""
prepare_fieldmap.py

prepare_fieldmap path-to-fieldmap-files

1) Creates a pair of magnitude niftis from dicoms
2) Creates a phase nifti from dicoms
3) Masks the mag1 image, giving an opportunity for tightening masking by hand
4) Prepares a fieldmap for use with FSL FEAT
5) Moves all niftis to nifti directory. Makes a directory if none exists.

Assumes: 
magnitude dicoms are in a directory starting with MR
phase dicoms are in a directory starting with PH
these are subdirectories of the fieldmapping directory, which is a command line input
fieldmap_deltaTE is defined within the script (=1.02 ms as of 2013-01-08)

Created by Rachel Denison on 2013-01-08.
"""

import sys
import os
import glob


def do_commands(commands):
    """Print and do commands"""
    for command in commands:
        print command
        out = os.system(command)
        if out!=0:
            print 'command failed'
            break


def mag_nifti():
    """Make magnitude niftis"""
    commands = [
        'dcm2nii -f MR*/*.dcm',
        'fslsplit MR*/*.nii.gz mag',
        'mv mag0000.nii.gz mag1.nii.gz',
        'mv mag0001.nii.gz mag2.nii.gz',
        'rm MR*/*.nii.gz']
    
    print '\nMaking magnitude niftis ...'
    do_commands(commands)
    
    
def phase_nifti():
    """Make phase nifti"""
    commands = [
        'dcm2nii -f PH*/*.dcm',
        'mv PH*/*.nii.gz phase.nii.gz']

    print '\nMaking phase nifti ...'
    do_commands(commands)
    
    
def mask_mag():
    """Mask mag image and erode to make tight mask"""
    commands = [
        # Brain mask mag1 image using FSL defaults
        'bet mag1.nii.gz mag1_masked.nii.gz',
        # Erode masked image, use a spherical kernel of 5 mm for the erosion
        #'fslmaths mag1_masked.nii.gz -kernel sphere 5 -ero mag1_masked_e.nii.gz'
        # Erode masked image x2
        'fslmaths mag1_masked.nii.gz -ero -ero mag1_masked_e.nii']

    print '\nMasking mag ...'
    do_commands(commands)
    
    
def finish_mag_mask():
    """If you've created a final erosion mask by hand using afni, apply it to the mag image"""
    commands = [
        # afni to nifti
        '3dAFNItoNIFTI final_erode_mask+orig',
        'gzip final_erode_mask.nii',
        # flip polarity of mask, so regions to be masked = 0, everywhere else = 1
        'fslmaths final_erode_mask.nii.gz -mul -1 -add 1 final_erode_mask_inv.nii.gz'   
        # check that vals are 0 and 1, with many more 1 vals than 0 vals
        'fslstats final_erode_mask_inv.nii.gz -R -h 2',
        # apply extra masking to mag1, overwrite _e
        'fslmaths mag1_masked_e.nii.gz -mul final_erode_mask_inv.nii.gz mag1_masked_e.nii.gz']
        
    print '\nApplying additional hand-made mask ...'
    do_commands(commands)


def fieldmap(deltaTE):
    """Prepare fieldmap using FSL"""
    os.system('fsl_prepare_fieldmap SIEMENS phase.nii.gz mag1_masked_e.nii.gz fieldmap.nii.gz {}'.format(deltaTE))  
    

def niftis_to_nifti_dir():
    """Move all the niftis in the current directory to a _nifti directory.
    If the directory does not yet exist, create it."""
    nifti_dirs = glob.glob('*_nifti')
    if len(nifti_dirs)>1:
        print 'Too many nifti dirs found. Niftis will not be moved.'
    else:
        if len(nifti_dirs)==0:
            print('\nNo _nifti directory found, creating ...')
            os.system('mkdir field_map_nifti')
        os.system('mv *.nii.gz *_nifti/')

    
if __name__ == '__main__':

    #The full path to the session files is a command-line argument: 
    sess_dir = sys.argv[1]
    if sess_dir[-1]=='/': #If a trailing backslash has been input
        sess_dir=sess_dir[:-1]
    # sess_name = os.path.split(sess_dir)[1]

    # User-defined parameters:    
    # delta TE for fsl_prepare_fieldmap (in ms)
    fieldmap_deltaTE = 1.02
    print '\nFieldmap deltaTE is set to {} ms'.format(fieldmap_deltaTE)
    raw_input("Press Enter to accept...")
    # Perform an additional masking of the magnitude image by hand?
    mask_mag_by_hand = False

    # Switch to session directory:
    os.chdir(sess_dir)
    # Tell us where we are
    print os.path.realpath(os.path.curdir)

    # Convert phase and magnitude dicoms to niftis
    mag_nifti()
    phase_nifti()

    # Mask the magnitude image
    mask_mag()

    # Finish off masked mag image, with masking by hand if requested
    if mask_mag_by_hand:
        print '\nNow is the time to create the final masked magnitude image!'
        raw_input("Press Enter when ready to continue...") # may need updating to input() with Python 3
        finish_mag_mask()
    
    # Prepare fieldmap
    fieldmap(fieldmap_deltaTE)

    # Clean up -- move all nifti files to nifti directory
    niftis_to_nifti_dir()
