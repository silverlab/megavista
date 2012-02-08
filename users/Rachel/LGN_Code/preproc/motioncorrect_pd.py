#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#motioncorrect_pd.py

"""This script uses mcflirt to run motion correction on 4d niftis.
These niftis should already be in the file structure expected by mrVista,
which can be created using dicom2vista_pd.py.

This script will attempt to motion correct all files that are located in the
session _nifti directory. It will motion correct to the n+1 volume in the
series.

2011-Oct-17 RD wrote it, modified from motioncorrect_pd.py
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
    nifti_dir = sess_dir + '/' + sess_name + '_nifti/'

    nifti_list = np.array(os.listdir(nifti_dir)) 
    #In order to not include '.DS_store'
    pd_list = []
    for file in nifti_list:
        if not file.startswith('.'):
            pd_list.append(file)

    os.chdir(nifti_dir)
    print os.path.realpath(os.path.curdir)

    # Do motion correction on epis      
    for this_pd in pd_list: 
        #Run mcflirt motion correction on the 4d nifti file. 
        #The params (cost=mutualinfo and smooth=16) are taken from the 
        #Berkeley shell-script AlignFSL070408.sh:
        print('Motion correction for ' + this_pd)
        
        os.system('mcflirt -stats -plots -report ' +
                  '-cost mutualinfo -smooth 16 -in ' + this_pd)	
	
