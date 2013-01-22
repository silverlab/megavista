#!/bin/bash
# rd_regress_nuisance.sh
#
# This script was modeled after example at 
# http://www.nitrc.org/forum/forum.php?thread_id=1495&forum_id=1383
# posted by Lisa Eyler: "RE: Nuisance signal regression and resting ep"

func_dir='/Volumes/Plata1/LGN/Scans/7T/JN_20120808_Session/JN_20120808_fslDC/JN_20120808_fslDC_nifti'
func='epi01_fix_fsldc'
mask_dir='/Volumes/Plata1/LGN/Scans/7T/JN_20120808_Session/JN_20120808_fslDC/Masks'
mask='automask'
nuisance_dir='/Volumes/Plata1/LGN/Scans/7T/JN_20120808_Session/JN_20120808_fslDC/ConnectivityAnalysis/regressors'

## 6. Generate mat file (for use later)
echo "Running 3dDeconvolve to get matrix"
3dDeconvolve -input ${func_dir}/${func}.nii.gz -force_TR 2.0 \
-nfirst 15 -nlast 179 \
-mask ${mask_dir}/${mask}.nii.gz \
-num_stimts 8 -polort 0 \
-stim_file 1 ${nuisance_dir}/mc1.1D \
-stim_file 2 ${nuisance_dir}/mc2.1D \
-stim_file 3 ${nuisance_dir}/mc3.1D \
-stim_file 4 ${nuisance_dir}/mc4.1D \
-stim_file 5 ${nuisance_dir}/mc5.1D \
-stim_file 6 ${nuisance_dir}/mc6.1D \
-stim_file 7 ${nuisance_dir}/csf.1D \
-stim_file 8 ${nuisance_dir}/wm.1D \
-x1D ${nuisance_dir}/xmat.1D \
-xjpeg ${nuisance_dir}/xmat.jpg \
-x1D_stop


## 7. Get residuals
rm -fr ${nuisance_dir}/stats_afni
mkdir ${nuisance_dir}/stats_afni
echo "Running 3dREMLfit to get residuals"
3dREMLfit -input ${func_dir}/${func}.nii.gz \
-mask ${mask_dir}/${mask}.nii.gz \
-matrix ${nuisance_dir}/xmat.1D \
-Rerrts ${nuisance_dir}/stats_afni/res4d.nii.gz \
-Oerrts ${nuisance_dir}/stats_afni/ores4d.nii.gz \
-GOFORIT