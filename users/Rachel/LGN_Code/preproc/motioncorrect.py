#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#motioncorrect.py

"""This script uses mcflirt to run motion correction on 4d niftis.
These niftis should already be in the file structure expected by mrVista,
which can be created using dicom2vista_org.py.

This script will attempt to motion correct all files starting with 'epi'
that are located in the session _nifti directory. It will motion correct
to a reference volume, which is the first volume in the scan. It expects
this volume to be found in the session _dicom directory in a subdirectory 
starting with 'epi01'.

2011-Oct-17 RD wrote it, modified from dicom2vista_rd.py
""" 

import os
import glob
import numpy as np
import sys

from matplotlib import pyplot as plt

if __name__ == "__main__":
	
    #The full path to the session files is a command-line argument: 
    sess_dir = sys.argv[1]
    if sess_dir[-1]=='/': #If a trailing backslash has been input
        sess_dir=sess_dir[:-1]
    sess_name = os.path.split(sess_dir)[1]

    #switch to session directory:
    os.chdir(sess_dir)
    print os.path.realpath(os.path.curdir)

    #Directory names: these directories are expected
    dicom_dir = sess_dir + '/' + sess_name + '_dicom/'
    nifti_dir = sess_dir + '/' + sess_name + '_nifti/'

    nifti_list = np.array(os.listdir(nifti_dir)) 
    #In order to not include '.DS_store'
    epi_list = []
    for file in nifti_list:
        if file.startswith('epi'):
            epi_list.append(file)

    os.chdir(nifti_dir)
    print os.path.realpath(os.path.curdir)

    # Do motion correction on epis      
    for this_epi in epi_list: 
        #In the first epi directory, convert the first image to nifti,
        #to be used in motion correction afterwards as reference:
        if this_epi.startswith('epi01'):
            print('Creating reference volume from first epi volume')
            epi1_dir = os.path.splitext(os.path.splitext(this_epi)[0])[0]
            os.chdir(dicom_dir + epi1_dir)
            print os.path.realpath(os.path.curdir)

            os.system('dcm2nii -g N -v N *0001.dcm')
            os.system('mv *.nii ref_vol.nii')
                           
            #Move ref_vol to nifti directory
            ref_vol_path = nifti_dir + 'ref_vol.nii'
            os.system('mv ref_vol.nii ' + ref_vol_path)

            os.chdir(nifti_dir)
            print os.path.realpath(os.path.curdir)
        
        #Run mcflirt motion correction on the 4d nifti file with 
        #reference to the first volume in the first epi (this assumes 
        #that the gems were acquired right before the first run). 
        #The params (cost=mutualinfo and smooth=16) are taken from the 
        #Berkeley shell-script AlignFSL070408.sh:
        print('Motion correction for ' + this_epi)
        
        os.system('mcflirt -reffile ' + ref_vol_path +
              ' -plots -report -cost mutualinfo -smooth 16 -in ' + 
              this_epi)

	    #Remove the file that was used as reference for MC:
	    # os.system('rm ' + ref_vol_path)
	
	