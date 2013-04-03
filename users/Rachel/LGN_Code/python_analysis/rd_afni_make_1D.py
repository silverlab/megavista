#!/usr/bin/env python
# encoding: utf-8
"""
rd_afni_make_1D.py

Created by Local Administrator on 2012-12-20.
Copyright (c) 2012 __MyCompanyName__. All rights reserved.
"""

import sys
import os

import numpy as np


def txt_to_1D(txt_file, out_file_base):
	"""
	txt_file is a text file with array-like data
	the columns of txt_file will be saved as separate .1D files
	out_file_base is the prefix for the saved files
	the column number (1...ncolumns) will be appended to the prefix
	"""
	# read in par file
	data = np.loadtxt(txt_file)
	
	# save the columns of data as separate .1D files
	for i in xrange(data.shape[1]):
		out_file = '{0}{1}.1D'.format(out_file_base, i+1)
		np.savetxt(out_file, data[:,i])


if __name__ == '__main__':
	txt_file = 'prefiltered_func_data_mcf.par'
	out_file_base = 'mc'
	
	txt_to_1D(txt_file, out_file_base)

