#!/usr/bin/env python
# encoding: utf-8
"""
testy.py

Created by Local Administrator on 2012-11-13.
"""

roi_im = np.zeros(volume_shape)
seed_name = seed_rois[0]
seed_file = os.path.join(roi_dir, '{}.mat'.format(seed_name))
seed_coords = tsv.upsample_coords(tsv.getROIcoords(seed_file), upsample_factor)
coords_indices = list(seed_coords)
roi_im[coords_indices] = 1

visualize.display_slices(roi_im, 0, 1)

roi_nii = nib.Nifti1Image(roi_im, data.get_affine())
roi_nii.to_filename(os.path.join(out_dir, seed_name))

######

nan_im  = np.isnan(coh_im)
visualize.display_slices(nan_im)
nan_im.sum()

####### 
