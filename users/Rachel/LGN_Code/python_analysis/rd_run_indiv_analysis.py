#!/usr/bin/env python
# encoding: utf-8
"""
rd_run_indiv_analysis.py

Created by Rachel on 2012-03-22.
"""

import os, glob, sys
import scipy.io as sio
import matplotlib.pylab as pl

import rd_lgn_spatial_svm
import rd_plot_svc_coef


scanner = '3T'
sdirs = sio.loadmat('/Volumes/Plata1/LGN/Group_Analyses/subjectDirs.mat')

if scanner=='3T':
    subject_dirs = sdirs['subjectDirs3T']
elif scanner=='7T':
    subject_dirs = sdirs['subjectDirs7T']
    
# subjects = range(subject_dirs.shape[0])
subjects = [2]
    
for subject in subjects:
    data_dir = '/Volumes/Plata1/LGN/Scans/{0}/{1}/{2}/ROIAnalysis/{3}'.format(
    scanner, subject_dirs[subject,0][0], subject_dirs[subject,1][0], 
    subject_dirs[subject,2][0])

    print data_dir
    os.chdir(data_dir)

    # os.system('python ~/Software/megavista/users/Rachel/LGN_Code/python_analysis/\
# rd_lgn_spatial_svm.py')

    svc = rd_lgn_spatial_svm.main()
    rd_plot_svc_coef.main(svc)
