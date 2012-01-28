README
python_preproc

Python scripts for preprocessing dicom data, in preparation for analysis in mrVista.

Run the scripts in this order from the command line:

1. dicom2vista_org.py
Takes one argument, the file path where the data are located. Expects epi data to be in folders starting with epi ("epi01", "epi02", etc). After "epi" and the scan number, the folder name can have any other characters ("epi01_attention", "epi02_fixation", etc are ok). It also expects a folder called "gems", but it's ok if this does not exist.
This script makes backup data folders and organizes the files into a convenient folder structure for running mrInit2. ("org" stands for "organize")
Must have dcm2nii from mricron installed.

2. motioncorrect.py
Uses FSL McFlirt routines to perform rigid-body motion correction on the epis. 
Must have FSL installed.

3. motionparams.py
Uses the motion correction results file created by motioncorrect.py to plot the motion correction parameters.

Note that these scripts are fairly independent of one another, so you don't have to run all three (for example, if you want to do motion correction a different way, you can run only dicom2vista_org.py.

The Enthought distribution of python should provide all the python toolboxes you need to run these scripts.

----------------------------------------------------------------------
Rachel Denison
16 Jan 2012
