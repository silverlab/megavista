#!/bin/sh
# this version does not allow reslicing but allows forcing output orientation
# inputs are subjectID output_orientation_code (RAS... assuming letters code for direction)
export vol0=orig
export vol1=nu
export vol2=brain
export vol3=ribbon
export vol4=T1

# CONVERT TO NIFTI:
mri_convert --out_orientation $2  $FREESURFER_HOME/subjects/$1/mri/$vol0.mgz $1_${vol0}_$2_NoRS.nii.gz
mri_convert --out_orientation $2  $FREESURFER_HOME/subjects/$1/mri/$vol1.mgz $1_${vol1}_$2_NoRS.nii.gz
mri_convert --out_orientation $2  $FREESURFER_HOME/subjects/$1/mri/$vol2.mgz $1_${vol2}_$2_NoRS.nii.gz
mri_convert --out_orientation $2  $FREESURFER_HOME/subjects/$1/mri/$vol3.mgz $1_${vol3}_$2_NoRS.nii.gz
mri_convert --out_orientation $2  $FREESURFER_HOME/subjects/$1/mri/$vol4.mgz $1_${vol4}_$2_NoRS.nii.gz

echo 'Non reslicing version of mgz2nii.sh (mgz2niiOrNoRS.sh / Chopin 2015) -> output orientation is ' $2
echo 'Done converting Freesurfer volumes...'