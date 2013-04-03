#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#dicom2vista_t1.py

"""This script takes the raw dicoms as they come off the scanner, and
creates the environment that mrVista expects to find, when running
mrInit2

Includes creating a backup of the dicoms, converting the dicoms to niftis,
and creating the mrVista file structure.

100109 ASR wrote it
2011-Oct-17 RD edited it, modified from dicom2vista_org.py
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
    t1_list = []
    for file in dir_list:
        if file.startswith('t1'):
            t1_list.append(file)
    dir_list = t1_list
    #Make the expected directory structure
    try:
        os.mkdir(sess_name+'_dicom')
        os.mkdir(sess_name+'_nifti')
    except:
        print 'Directories already exist'
    #Directory names
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
 
    #After doing all that copy stuff into the right places:
    for this_dir in dir_list:
        os.chdir(sess_dir)
        print os.path.realpath(os.path.curdir)
        os.system('mv ' + this_dir + ' ' + dicom_dir)
    
        os.chdir(dicom_dir + this_dir)
        print os.path.realpath(os.path.curdir)
        os.system('mv *.nii.gz ' + nifti_dir)

    #Then use dcm2nii gui to convert 3d .nii.gz files to one 4d FSL file
    #Move this to the _nifti directory
    #Now we are ready for fsl motion correction 
