#!/bin/sh
# this version forces reslicing but not the output orientation - it also converts T1.mgz
# Usage: mgz2niiRS.sh subjectID resliceLikeFile
export vol0=orig
export vol1=nu
export vol2=brain
export vol3=ribbon
export vol4=T1

# CONVERT TO NIFTI:
mri_convert --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol0.mgz $1_RS_$vol0.nii.gz
mri_convert --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol1.mgz $1_RS_$vol1.nii.gz
mri_convert --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol2.mgz $1_RS_$vol2.nii.gz
mri_convert --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol3.mgz $1_RS_$vol3.nii.gz
mri_convert --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol4.mgz $1_RS_$vol4.nii.gz

echo "Version modified in 2015 (Chopin) to convert also T1.mgz and reslicing like $2"
echo "done converting Freesurfer volumes"
