# seed_analysis.py

import os

import numpy as np
import matplotlib.pyplot as plt
import scipy.io as sio
import scipy.stats as stats

import nibabel as nib

import nitime.analysis as nta
import nitime.fmri.io as ntio

import rd_nipy_visualize as visualize

# subject and scanner
scanner = '7T'
subject = 9
hemi = 2

# ROIs to use as seeds
roi_names = ['M','P']

# define TR and frequency band of interest
#roi_name = 'V3'
TR = 2
f_lb = 0.017 # 0.0167 = 60 s/cycle
f_ub = 0.15
nfft = 20

# save results?
save_nii = 1
save_fig = 1

# file i/o
sdirs = sio.loadmat('/Volumes/Plata1/LGN/Group_Analyses/subjectDirs_20121103.mat')

if scanner=='3T':
    subject_dirs = sdirs['subjectDirs3T']
elif scanner=='7T':
    subject_dirs = sdirs['subjectDirs7T']

session_dir = str(os.path.join('/Volumes/Plata1/LGN/Scans',
    scanner, subject_dirs[subject,0][0], subject_dirs[subject,1][0]))
nifti_dir = os.path.join(session_dir, '{}_nifti'.format(subject_dirs[subject,1][0]))

# fmri_file = os.path.join(nifti_dir, 'epi01_fix_fsldc.nii.gz')
fmri_file = os.path.join(session_dir, 'ConnectivityAnalysis/nifti/fix_fsldc_minute2.nii.gz')
mask_file = os.path.join(session_dir, 'Masks/automask.nii.gz')

print session_dir
print fmri_file

for roi_name in roi_names:
    print '\n', roi_name
    roi_file = os.path.join(session_dir, 
        'Masks/lgnROI{0}_comVoxGroupCoords_betaM-P_prop20_varThresh000_{1}roi_flip.nii'.format(hemi, roi_name))
    coh_nii_file = os.path.join(session_dir, 'ConnectivityAnalysis/lgnROI{0}_cohSeed_{1}.nii.gz'.format(hemi, roi_name))
    cor_nii_file = os.path.join(session_dir, 'ConnectivityAnalysis/lgnROI{0}_corSeed_{1}.nii.gz'.format(hemi, roi_name))
    coh_fig_file = os.path.join(session_dir, 'ConnectivityAnalysis/lgnROI{0}_cohSeed_{1}.png'.format(hemi, roi_name))
    cor_fig_file = os.path.join(session_dir, 'ConnectivityAnalysis/lgnROI{0}_corSeed_{1}.png'.format(hemi, roi_name))
    
    # load data
    fmri_data = nib.load(fmri_file)
    mask_data = nib.load(mask_file)
    roi_data = nib.load(roi_file)
    
    # get volume info
    volume_shape = fmri_data.shape[:-1]
    #coords = list(np.ndindex(volume_shape))
    #coords_target = np.array(coords).T
    
    # find the coordinates of the roi voxels
    roi_vals = roi_data.get_data()
    roi_coords = np.array(np.where(roi_vals==1))
    coords_seed = roi_coords
    
    # find the coordinates of cortex voxels
    mask_vals = mask_data.get_data()
    cortex_coords = np.array(np.where(mask_vals==1))
    coords_target = cortex_coords
    
    # make the seed time series (mean of roi time series)
    time_series_seed = ntio.time_series_from_file(fmri_file,
                        coords_seed,
                        TR=TR,
                        normalize=None,
                        average=True,
                        filter=dict(lb=f_lb,
                            ub=f_ub,
                            method='boxcar'),
                        verbose=True)
                        
    # make the target time series (all voxels in cortex)
    time_series_target = ntio.time_series_from_file(fmri_file,
                        coords_target,
                        TR=TR,
                        normalize=None,
                        filter=dict(lb=f_lb,
                            ub=f_ub,
                            method='boxcar'),
                        verbose=True)
    
    # coherence analyzer
    cohA = nta.SeedCoherenceAnalyzer(time_series_seed, time_series_target,
                method=dict(NFFT=nfft))
    
    # correlation analyzer
    corA = nta.SeedCorrelationAnalyzer(time_series_seed, time_series_target)
    
    # select frequency band
    freq_idx = np.where((cohA.frequencies > f_lb) * (cohA.frequencies < f_ub))[0]
    
    # extract correlation and coherence values
    print 'Calculating correlation and coherence'
    coh_coherence = cohA.coherence
    coh = np.mean(coh_coherence[:, freq_idx], -1)
    cor = corA.corrcoef
    
    # make coh and cor images
    coords_indices = list(coords_target)
    
    coh_im = np.zeros(volume_shape)
    cor_im = np.zeros(volume_shape)
    
    coh_im[coords_indices] = coh
    cor_im[coords_indices] = cor
    
    # save the images as niftis
    if save_nii:
        print 'Saving niftis'
        coh_nii = nib.Nifti1Image(coh_im, fmri_data.get_affine())
        cor_nii = nib.Nifti1Image(cor_im, fmri_data.get_affine())
        
        coh_nii.to_filename(coh_nii_file)
        cor_nii.to_filename(cor_nii_file)
    
    # display the coh and coh maps
    fig_coh = visualize.display_slices(coh_im, min_val=0, max_val=1, cmap=plt.cm.RdBu_r)
    fig_coh.suptitle('coherence, hemi {0} {1} seed'.format(hemi, roi_name))
    
    fig_cor = visualize.display_slices(cor_im, min_val=-1, max_val=1, cmap=plt.cm.RdBu_r)
    fig_cor.suptitle('correlation hemi {0} {1} seed'.format(hemi, roi_name))
    
    # save the figures
    if save_fig:
        print 'Saving figs'
        fig_coh.savefig(coh_fig_file)
        fig_cor.savefig(cor_fig_file)

    plt.show()
    
    
