# rd_nipy_connectivity_roi_to_roi.py

import os

import numpy as np
import matplotlib.pyplot as plt
import scipy.io as sio
import scipy.stats as stats

import nibabel as nib

import nitime.analysis as nta
import nitime.fmri.io as ntio
import nitime.timeseries as ntts
import nitime.viz as viz

import vista_utils as tsv
import rd_nipy_visualize as visualize

# file i/o
session_dir = '/Volumes/Plata1/LGN/Scans/7T/JN_20120808_Session/JN_20120808_fslDC/'
roi_dir = os.path.join(session_dir, 'Inplane/ROIs/')
data_dir = os.path.join(session_dir, 'ConnectivityAnalysis/nifti/')
out_dir = os.path.join(session_dir, 'ConnectivityAnalysis/')

data_file = os.path.join(data_dir, 'fix_fsldc_minute2.nii.gz')

# ROIs to use as seeds
seed_rois = ['LLGN_ecc0','LLGN_ecc14','LLGN_polar0','LLGN_polar5',
    'RLGN_ecc2','RLGN_ecc9','RLGN_polar2','RLGN_polar4']

# ROIs to use as targets
target_rois = ['LV1_ecc0-2', 'LV1_ecc10-18', 'LV1_polar602-026', 'LV1_polar474-526',
     'RV1_ecc1-3', 'RV1_ecc7-11', 'RV1_polar174-226', 'RV1_polar374-426']

# define upsample factor, TR, and frequency band of interest
upsample_factor = [1.0000,1.0000,1.0000] #upsample factor from EPI to GEM
TR = 2
f_lb = 0.01
f_ub = 0.15

# save results?
save_nii = 1
save_fig = 1

# load data
data = nib.load(data_file)
volume_shape = data.shape[:-1]
n_TRs = data.shape[-1]

# Get seed data
# initialize seed time series
seed_ts = np.zeros((len(seed_rois), n_TRs))

for i_seed, seed_name in enumerate(seed_rois):
    print '\n', seed_name
    seed_file = os.path.join(roi_dir, '{}.mat'.format(seed_name))
    
    # get the coordinates of the seed voxels
    seed_coords = tsv.upsample_coords(tsv.getROIcoords(seed_file), upsample_factor)

    # make the seed time series (mean of roi time series)
    # this is a little odd - reads the data as a TimeSeries, then just takes the data ...
    seed_ts[i_seed] = ntio.time_series_from_file(data_file,
                        coords=seed_coords,
                        TR=TR,
                        normalize='percent',
                        average=True,
                        filter=dict(lb=f_lb,
                            ub=f_ub,
                            method='boxcar'),
                        verbose=True).data

seed_T = ntts.TimeSeries(seed_ts, sampling_interval=TR)
fig = viz.plot_tseries(seed_T)

seed_Cor = nta.CorrelationAnalyzer(seed_T)
fig = viz.drawmatrix_channels(seed_Cor.corrcoef, seed_rois, color_anchor=0)

# Get target data
# initialize target time series
target_ts = np.zeros((len(target_rois), n_TRs))

for i_target, target_name in enumerate(target_rois):
    print '\n', target_name
    target_file = os.path.join(roi_dir, '{}.mat'.format(target_name))

    # find the coordinates of cortex voxels
    target_coords = tsv.upsample_coords(tsv.getROIcoords(target_file), upsample_factor)

    # make the target time series
    target_data = ntio.time_series_from_file(data_file,
                        coords=target_coords,
                        TR=TR,
                        normalize='percent',
                        average = False,
                        filter=dict(lb=f_lb,
                            ub=f_ub,
                            method='boxcar'),
                        verbose=True).data

    nan_targets = np.isnan(np.mean(target_data,1))
    print '\n', nan_targets.sum(), 'voxels with nan values ... removing'
    target_ts[i_target] = np.mean(target_data[~nan_targets,:],0) # take average across voxels

target_T = ntts.TimeSeries(target_ts, sampling_interval=TR)
fig = viz.plot_tseries(target_T)

target_Cor = nta.CorrelationAnalyzer(target_T)
fig = viz.drawmatrix_channels(target_Cor.corrcoef, target_rois, color_anchor=0)

# correlation analyzer
seed_target_Cor = nta.SeedCorrelationAnalyzer(seed_T, target_T)

# show correlation matrix
visualize.display_matrix(seed_target_Cor.corrcoef, 
    xlabels=seed_rois, ylabels=target_rois, cmap=plt.cm.RdBu_r,color_anchor=0)

# coherence analyzer
seed_target_Coh = nta.SeedCoherenceAnalyzer(seed_T, target_T,
            method=dict(NFFT=30))
visualize.display_matrix(np.mean(seed_target_Coh.coherence,2), 
    xlabels=seed_rois, ylabels=target_rois, cmap=plt.cm.RdBu_r, color_anchor=0)

print 'stopped working here!'
0/0

# select frequency band
freq_idx = np.where((cohA.frequencies > f_lb) * (cohA.frequencies < f_ub))[0]

# extract correlation and coherence values
print 'Calculating correlation and coherence'
coh = np.mean(cohA.coherence[:, freq_idx], -1)
cor = corA.corrcoef

# make coh and cor images
coords_indices = list(target_coords)

coh_im = np.zeros(volume_shape)
cor_im = np.zeros(volume_shape)

coh_im[coords_indices] = coh
cor_im[coords_indices] = cor
   
# save the images as niftis
if save_nii:
	print 'Saving niftis'
	coh_nii = nib.Nifti1Image(coh_im, data.get_affine())
	cor_nii = nib.Nifti1Image(cor_im, data.get_affine())

	coh_nii.to_filename(coh_nii_file)
	cor_nii.to_filename(cor_nii_file)

# display the coh and coh maps
fig_coh = visualize.display_slices(coh_im, 0, 1)
fig_coh.suptitle('coherence, {0} seed'.format(seed_name))
plt.show()

fig_cor = visualize.display_slices(cor_im, 0, 1)
fig_cor.suptitle('correlation {0} seed'.format(seed_name))
plt.show()

# save the figures
if save_fig:
	print 'Saving figs'
	fig_coh.savefig(coh_fig_file)
	fig_cor.savefig(cor_fig_file)
   
   
