#!/usr/bin/env python
# encoding: utf-8
"""
rd_nifti_to_png.py

Created by Rachel Denison on 2012-12-19.
"""

import os

import numpy as np
import matplotlib.pyplot as plt

import nibabel as nib

import rd_nipy_visualize as visualize


def show_nifti(name, nifti_dir=None, save_fig=0, fig_dir=None):
    """
    name is the name of the nifti file, without the nii.gz extension
    nifti_dir is the path to the directory where the nifti is located. if not provided, looks in current directory.
    save_fig is 1 for save nifti fig as png, 0 for don't save
    fig_dir is the path to the directory for saving the png. if not provided, saves to nifti_dir
    """
    if nifti_dir==None:
	    nifti_dir = os.getcwd()
    im = nib.load(os.path.join(nifti_dir, '{}.nii.gz'.format(name)))
    data = im.get_data()
    min_val = data[~np.isnan(data)].min()
    max_val = data[~np.isnan(data)].max()
    fig = visualize.display_slices(data, min_val=min_val, max_val=max_val, cmap=plt.cm.RdBu_r)
    fig.suptitle(name)
    # plt.show()
    if save_fig:
        if fig_dir==None:
            fig_dir = nifti_dir
        fig.savefig(os.path.join(fig_dir,'{}.png'.format(name)))


if __name__ == '__main__':
    nifti_dir = '/Volumes/Plata1/LGN/Scans/7T/JN_20120808_Session/JN_20120808_fslDC/ConnectivityAnalysis'
    fig_dir = os.path.join(nifti_dir, 'figures')
    names = ['lgnROI1_cohSeed_M-P','lgnROI1_corSeed_M-P','lgnROI2_cohSeed_M-P','lgnROI2_corSeed_M-P',
        'lgnROI1-2_cohSeed_M','lgnROI1-2_cohSeed_P','lgnROI1-2_corSeed_M','lgnROI1-2_corSeed_P']

    for name in names:
        show_nifti(name, nifti_dir, save_fig=1, fig_dir=fig_dir)

