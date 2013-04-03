#!/usr/bin/env python
# encoding: utf-8
"""
rd_segment_scan.py

Created by Rachel Denison on 2012-12-21.

Chops a nifti into [n_segments] of length [segment_length] (in TRs).
Saves each segment as a numbered nifti in the same directory as the 
original data.
Dependencies: FSL
"""

import os

import numpy as np


# file i/o
session_dir = '/Volumes/Plata1/LGN/Scans/7T/JN_20120808_Session/JN_20120808_fslDC/'
data_dir = os.path.join(session_dir, 'ConnectivityAnalysis/regressors/stats_afni/')
fmri_file = 'ores4d'
fmri_path = os.path.join(data_dir, fmri_file)

n_segments = 6
segment_length = 30 # in TRs
t_start = 0

for i, t0 in enumerate(segment_length*np.arange(n_segments) + t_start):
    print t0
    cmd = 'fslroi {name}.nii.gz {name}_minute{iseg}.nii.gz {tmin} {tsize}'.format(
    name=fmri_path, iseg=i+1, tmin=t0, tsize=segment_length)
    print cmd
    os.system(cmd)


