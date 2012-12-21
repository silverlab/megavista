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
mask_roi_dir = os.path.join(session_dir, 'Masks/')
mrvista_roi_dir = os.path.join(session_dir, 'Inplane/ROIs/')
data_dir = os.path.join(session_dir, 'ConnectivityAnalysis/nifti/')
out_dir = os.path.join(session_dir, 'ConnectivityAnalysis/')


minute = 2
data_file = os.path.join(data_dir, 'fix_fsldc_minute{}.nii.gz'.format(minute))

cor_fig_file = os.path.join(out_dir, 'figures', 'MP-Ret_cor_min{}.png'.format(minute))
coh_fig_file = os.path.join(out_dir, 'figures', 'MP-Ret_coh_min{}.png'.format(minute))

# roi_type can be 'mask' (nifti mask) or 'mrvista' (saved roi.mat files)
seed_roi_type = 'mask'
target_roi_type = 'mrvista'
# flip the image in the x dimension? this is needed if working with mrvista rois
flip_mrvista_x = True

# ROIs to use as seeds
# seed_rois = ['LLGN_ecc0','LLGN_ecc14','LLGN_polar0','LLGN_polar5',
#     'RLGN_ecc2','RLGN_ecc9','RLGN_polar2','RLGN_polar4']
seed_rois = ['lgnROI1_comVoxGroupCoords_betaM-P_prop20_varThresh000_Mroi_flip',
    'lgnROI1_comVoxGroupCoords_betaM-P_prop20_varThresh000_Proi_flip',
    'lgnROI2_comVoxGroupCoords_betaM-P_prop20_varThresh000_Mroi_flip',
    'lgnROI2_comVoxGroupCoords_betaM-P_prop20_varThresh000_Proi_flip']

# ROIs to use as targets
# target_rois = ['LV1_ecc0-2', 'LV1_ecc10-18', 'LV1_polar602-026', 'LV1_polar474-526',
#      'RV1_ecc1-3', 'RV1_ecc7-11', 'RV1_polar174-226', 'RV1_polar374-426']
target_rois = ['LV1','LV2d','LV2v','LV3a','LV3d','LV3v','L_hMTplus',
    'LIPS0','LIPS1','LIPS2','LIPS3','LIPS4','LIPS5',
    'RV1','RV2d','RV2v','RV3a','RV3d','RV3v','R_hMTplus',
        'RIPS0','RIPS1','RIPS2','RIPS3','RIPS5',]

# define TR and frequency band of interest
#roi_name = 'V3'
upsample_factor = [1.0000,1.0000,1.0000] #upsample factor from EPI to GEM (for mrvista rois)
TR = 2
f_lb = 0.01
f_ub = 0.15
nfft = 20

# save results?
save_fig = 1

# load data
data = nib.load(data_file)
volume_shape = data.shape[:-1]
n_TRs = data.shape[-1]

# Get seed data
# initialize seed time series list
seed_ts = np.zeros((len(seed_rois), n_TRs))

for i_seed, seed_name in enumerate(seed_rois):
    print '\n', seed_name, seed_roi_type
    if seed_roi_type is 'mask':
        seed_file = os.path.join(mask_roi_dir, '{}.nii'.format(seed_name))

        # load roi mask
        seed_mask = nib.load(seed_file)
    
        # find the coordinates of the seed voxels
        seed_vals = seed_mask.get_data()
        seed_coords = np.array(np.where(seed_vals==1))
    elif seed_roi_type is 'mrvista':
        seed_file = os.path.join(mrvista_roi_dir, '{}.mat'.format(seed_name))

        # get the coordinates of the seed voxels
        seed_coords = tsv.upsample_coords(tsv.getROIcoords(seed_file), upsample_factor)

        if flip_mrvista_x:
            seed_coords[0] = (volume_shape[0]-1) - (seed_coords[0]) 
    else:
        print 'seed roi type not recognized'    

    # make the seed time series (mean of roi time series)
    seed_ts[i_seed] = ntio.time_series_from_file(data_file,
                        coords=seed_coords,
                        TR=TR,
                        normalize='percent',
                        average=True,
                        filter=dict(lb=f_lb,
                            ub=f_ub,
                            method='boxcar'),
                        verbose=True).data

    # seed_ts[i_seed] = ntio.time_series_from_file(data_file,
    #                     coords=seed_coords,
    #                     TR=TR,
    #                     average=True,
    #                     verbose=True).data

seed_T = ntts.TimeSeries(seed_ts, sampling_interval=TR)
fig = viz.plot_tseries(seed_T)

seed_Cor = nta.CorrelationAnalyzer(seed_T)
fig = viz.drawmatrix_channels(seed_Cor.corrcoef, seed_rois, color_anchor=0)


# Get target data
# initialize target time series list
target_ts = np.zeros((len(target_rois), n_TRs))

for i_target, target_name in enumerate(target_rois):
    print '\n', target_name, target_roi_type
    if target_roi_type is 'mask':
        target_file = os.path.join(mask_roi_dir, '{}.nii'.format(target_name))

        # load roi mask
        target_mask = nib.load(target_file)

        # find the coordinates of cortex voxels
        target_vals = target_mask.get_data()
        target_coords = np.array(np.where(target_vals==1))
    elif target_roi_type is 'mrvista':
        target_file = os.path.join(mrvista_roi_dir, '{}.mat'.format(target_name))

        # find the coordinates of cortex voxels
        target_coords = tsv.upsample_coords(tsv.getROIcoords(target_file), upsample_factor)

        if flip_mrvista_x:
            target_coords[0] = (volume_shape[0]-1) - (target_coords[0]) 
    else:
        print 'target roi type not recognized'      

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

# coherence analyzer
seed_target_Coh = nta.SeedCoherenceAnalyzer(seed_T, target_T,
            method=dict(NFFT=nfft))

# select frequency band
freq_idx = np.where((seed_target_Coh.frequencies > f_lb) * (seed_target_Coh.frequencies < f_ub))[0]

# extract correlation and coherence values
print 'Calculating correlation and coherence'
cor = seed_target_Cor.corrcoef
coh = np.mean(seed_target_Coh.coherence[:, :, freq_idx], -1)

# show correlation matrix
visualize.display_matrix(cor, 
    xlabels=target_rois, ylabels=seed_rois, cmap=plt.cm.RdBu_r,color_anchor=0)
fig_cor = plt.gcf()

# show coherence matrix
visualize.display_matrix(coh, 
    xlabels=target_rois, ylabels=seed_rois, cmap=plt.cm.RdBu_r, color_anchor=0)
fig_coh = plt.gcf()

# save the figures
if save_fig:
    print 'Saving figs'
    fig_cor.savefig(cor_fig_file)
    fig_coh.savefig(coh_fig_file)

   
   
