#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#dicom2vista_rd.py

"""This script takes the raw dicoms as they come off the scanner, and
creates the environment that mrVista expects to find, when running
mrInit2

100109 ASR wrote it
2011-Oct-17 RD edited it
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
    dir_list = np.array(os.listdir('.')) 
    #In order to not include '.DS_store'
    epi_list = []
    gems_list = []
    for file in dir_list:
        if file.startswith('epi'):
            epi_list.append(file)
        elif file.startswith('gems'):
            gems_list.append(file)
    dir_list = epi_list + gems_list
    #Make the expected directory structure
    try:
        os.mkdir(sess_name+'_backup')
        os.mkdir(sess_name+'_dicom')
        os.mkdir(sess_name+'_nifti')
        #Copy everything into the backups directory
        print("Making backups")
        for this_dir in dir_list:
            os.system('cp -r ' + this_dir + ' ' + sess_name + '_backup/')
    except:
        print 'Directories already exist'
    #Directory names
    backup_dir = sess_dir + '/' + sess_name + '_backup/'
    dicom_dir = sess_dir + '/' + sess_name + '_dicom/'
    nifti_dir = sess_dir + '/' + sess_name + '_nifti/'
    
    # Convert dicom to nifti
    for this_dir in dir_list: 
        print("Processing files in " + this_dir)
        os.chdir(sess_dir + '/' + this_dir)
        print ("Converting dicom files to nifti")
        
        #Run dcm2nii in order to do the conversion:
        if os.path.exists(this_dir + 'nii.gz') == False:
            print os.path.realpath(os.path.curdir)
            os.system('dcm2nii -f *.dcm this_dir')
        #Change the name of the new nii.gz file to match the directory name: 
        try:
            os.system('mv *.nii.gz ' + this_dir + '.nii.gz')
        except:
            print 'oops'
            sys.exit()
    
    # Do motion correction on epis      
    for this_dir in epi_list: 
        os.chdir(sess_dir + '/' + this_dir)
        print os.path.realpath(os.path.curdir)
        
        #In the first epi directory, convert the first image to nifti,
        #to be used in motion correction afterwards as reference:
        if this_dir.startswith('epi01'):
            print('Creating reference volume from first epi volume')

            os.system('dcm2nii -g N -v N *0001.dcm')
            os.system('mv *.nii ref_vol.nii')
                           
            #Move ref_vol to nifti directory
            ref_vol_path = nifti_dir + 'ref_vol.nii'
            os.system('mv ref_vol.nii ' + ref_vol_path)
        
        #Run mcflirt motion correction on the 4d nifti file with 
        #reference to the first volume in the first epi (this assumes 
        #that the gems were acquired right before the first run). 
        #The params (cost=mutualinfo and smooth=16) are taken from the 
        #Berkeley shell-script AlignFSL070408.sh:
        print('Motion correction for ' + this_dir)
        
        os.system('mcflirt -reffile ' + ref_vol_path +
              ' -plots -report -cost mutualinfo -smooth 16 -in ' + 
              this_dir + '.nii.gz')
 
    #After doing all that copy stuff into the right places:
    for this_dir in dir_list:
        os.chdir(sess_dir)
        print os.path.realpath(os.path.curdir)
        os.system('mv ' + this_dir + ' ' + dicom_dir)
    
        os.chdir(dicom_dir + this_dir)
        print os.path.realpath(os.path.curdir)
        os.system('mv *.nii.gz ' + nifti_dir)
        if this_dir.startswith('epi')
            os.sytem('mv *.par ' + nifti_dir)

    #Remove the file that was used as reference for MC:
    # os.system('rm ' + ref_vol_path)


