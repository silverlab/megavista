import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats
import pickle 
import datetime

import vista_utils as tsv # Get it at: https://github.com/arokem/vista_utils
from nitime.fmri.io import time_series_from_file as load_nii 
import nitime.timeseries as ts
import nitime.viz as viz

from nitime.analysis import CorrelationAnalyzer, CoherenceAnalyzer
#Import utility functions:
from nitime.utils import percent_change
from nitime.viz import drawmatrix_channels, drawgraph_channels
from nitime.viz import drawmatrix_channels, drawgraph_channels, plot_xcorr



if __name__ == "__main__":

	# Close any opened plots
	plt.close('all')
    
	base_path = '/Volumes/Plata1/DorsalVentral/' # Change this to your path
	fmri_path = base_path + 'fmri/'
	fileName='CG_all2012-01-27.pck'
	loadFile=fmri_path+'Results/' +fileName

	# Load the data
	print 'Loading subject coherence and correlation dictionaries.'
	file=open(loadFile, 'r')
	 # First file loaded is coherence
	cohAll=pickle.load(file)
	# Second file loaded is correlation
	corrAll=pickle.load(file)
	roiNames=pickle.load(file)
	file.close()

	for sub in cohAll:
		print sub
		numRuns=cohAll[sub].shape[0]
		# Average over runs (the first dimension)
		coherAvg=np.mean(cohAll[sub][:], 0)
		corrAvg=np.mean(corrAll[sub][:],0)
		# Plot graph
		fig1 = drawmatrix_channels(coherAvg, roiNames, size=[10., 10.], color_anchor=0, title='Average Coherence Results over ' +str(numRuns) + ' runs for ' + sub)
		fig2=drawmatrix_channels(corrAvg, roiNames, size=[10., 10.], color_anchor=0, title='Average Correlation Results over ' +str(numRuns) + ' runs for ' + sub)
		plt.show()
