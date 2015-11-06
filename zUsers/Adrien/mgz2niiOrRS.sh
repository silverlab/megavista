#!/bin/sh
# This version forces output_orientation and reslicing
# inputs are subjectID resliceLikeThisFile output_orientation_code (RAS...assuming letters code for direction)
export vol0=orig
export vol1=nu
export vol2=brain
export vol3=ribbon

# CONVERT TO NIFTI:
mri_convert --out_orientation $3 --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol0.mgz $1_${vol0}_$3.nii.gz
mri_convert --out_orientation $3 --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol1.mgz $1_${vol1}_$3.nii.gz
mri_convert --out_orientation $3 --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol2.mgz $1_${vol2}_$3.nii.gz
mri_convert --out_orientation $3 --reslice_like $2 $FREESURFER_HOME/subjects/$1/mri/$vol3.mgz $1_${vol3}_$3.nii.gz

echo "Reslicing version called mgz2niiOrient.sh s-> output orientation is $3 - Chopin 2015"
echo "done converting Freesurfer volumes"
