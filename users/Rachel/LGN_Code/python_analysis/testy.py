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

seed_cor_all = np.zeros((8,8,5))
target_cor_all = np.zeros((8,8,5))
cor_all = np.zeros((8,8,5))
coh_all = np.zeros((8,8,5))

# run rd_nipy_connectivity_roi_to_roi.py. each i is a minute-long segment.
seed_cor_all[:,:,i] = seed_Cor.corrcoef
target_cor_all[:,:,i] = target_Cor.corrcoef
cor_all[:,:,i] = cor
coh_all[:,:,i] = coh

ecc_polar_roi_all = {'seed_cor_all':seed_cor_all, 'target_cor_all':target_cor_all,
    'cor_all':cor_all, 'coh_all':coh_all}

pickle.dump(ecc_polar_roi_all, open(out_dir + 'res_ecc_polar_roi_all.pkl','wb'))
# testdata = pickle.load(open(out_dir + 'ecc_polar_roi_all.pkl','rb'))

seed_cor_mean = np.mean(seed_cor_all,-1)
target_cor_mean = np.mean(target_cor_all,-1)
cor_mean = np.mean(cor_all,-1)
coh_mean = np.mean(coh_all,-1)

seed_cor_std = np.std(seed_cor_all,-1)
target_cor_std = np.std(target_cor_all,-1)
cor_std = np.std(cor_all,-1)
coh_std = np.std(coh_all,-1)

# figures
fig_seed_cor = viz.drawmatrix_channels(seed_cor_mean, seed_rois, color_anchor=0)
fig_target_cor = viz.drawmatrix_channels(target_cor_mean, target_rois, color_anchor=0)

visualize.display_matrix(cor_mean, 
    xlabels=target_rois, ylabels=seed_rois, cmap=plt.cm.RdBu_r,color_anchor=0)
fig_cor = plt.gcf()

visualize.display_matrix(coh_mean, 
    xlabels=target_rois, ylabels=seed_rois, cmap=plt.cm.RdBu_r, color_anchor=0)
fig_coh = plt.gcf()

fig_seed_cor.savefig(out_dir + 'figures/LGN-LGN_Res_cor_mean.png')
fig_target_cor.savefig(out_dir + 'figures/V1-V1_Res_cor_mean.png')
fig_cor.savefig(out_dir + 'figures/LGN-V1_Res_cor_mean.png')
fig_coh.savefig(out_dir + 'figures/LGN-V1_Res_coh_mean.png')

fig_seed_cor.savefig(out_dir + 'figures/LGN-LGN_Res_cor_std.png')
fig_target_cor.savefig(out_dir + 'figures/V1-V1_Res_cor_std.png')
fig_cor.savefig(out_dir + 'figures/LGN-V1_Res_cor_std.png')
fig_coh.savefig(out_dir + 'figures/LGN-V1_Res_coh_std.png')


