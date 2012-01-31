#Changed on 1/30
import numpy as np
import scipy.stats as stats
import pickle 
import datetime

from matplotlib import mpl
from matplotlib import pyplot as plt
import matplotlib.ticker as ticker
import matplotlib.colors as colors
from mpl_toolkits.axes_grid import make_axes_locatable
from nitime.utils import triu_indices

import vista_utils as tsv # Get it at: https://github.com/arokem/vista_utils
from nitime.fmri.io import time_series_from_file as load_nii 
import nitime.timeseries as ts
import nitime.viz as viz

from nitime.analysis import CorrelationAnalyzer, CoherenceAnalyzer
#Import utility functions:
from nitime.utils import percent_change
from nitime.viz import drawmatrix_channels, drawgraph_channels, plot_xcorr

#Some visualization functions require networkx. Import that if possible:                         
try:
    import networkx as nx
    #If not, throw an error and get on with business:                                            
except ImportError:
    e_s = "Networkx is not available. Some visualization tools might not work"
    e_s += "\n To download networkx: http://networkx.lanl.gov/"
    print e_s
    class NetworkxNotInstalled(object):
        def __getattribute__(self,x):
            raise ImportError(e_s)
    nx = NetworkxNotInstalled()


def makePlot(in_m, channel_names=None, fig=None, x_tick_rot=0, size=None, 
	     cmap=plt.cm.RdBu_r, colorbar=True, color_anchor=None, title=None, max_val=None, min_val=None):

	N = in_m.shape[0]
	ind = np.arange(N)  # the evenly spaced plot indices                                                    

	def channel_formatter(x, pos=None):
		thisind = np.clip(int(x), 0, N - 1)
		return channel_names[thisind]

	if fig is None:
		fig=plt.figure()

	if size is not None:
		fig.set_figwidth(size[0])
		fig.set_figheight(size[1])
	wid=fig.get_figwidth()
	ht=fig.get_figheight()
	ax_im = fig.add_subplot(1, 1, 1)

	#If you want to draw the colorbar:
	# what is make_axes_locatable?
        divider = make_axes_locatable(ax_im)
        ax_cb = divider.new_vertical(size="20%", pad=0.2, pack_start=True)
        fig.add_axes(ax_cb)

	#Make a copy of the input, so that you don't make changes to the original                               
	#data provided                                                                                          
	m = in_m.copy()

	
	#Null the upper triangle, so that you don't get the redundant and
	#the diagonal values:                                                                            
	idx_null = triu_indices(m.shape[0])
	m[idx_null] = np.nan

	#Extract the minimum and maximum values for scaling of the
	#colormap/colorbar:
	if max_val is None:
		max_val = np.nanmax(m)
		min_val = np.nanmin(m)

	if color_anchor is None:
		color_min = min_val
		color_max = max_val
	elif color_anchor == 0:
		bound = max(abs(max_val), abs(min_val))
		color_min = -bound
		color_max = bound
	else:
		color_min = color_anchor[0]
		color_max = color_anchor[1]

	#The call to imshow produces the matrix plot:
	im = ax_im.imshow(m, origin='upper', interpolation='nearest',
	vmin=color_min, vmax=color_max, cmap=cmap)

	#Formatting:
	ax = ax_im
	ax.grid(True)
	#Label each of the cells with the row and the column:
	if channel_names is not None:
		for i in xrange(0, m.shape[0]):
			if i < (m.shape[0] - 1):
				ax.text(i - 0.3, i, channel_names[i], rotation=x_tick_rot)
			if i > 0:
				ax.text(-1, i + 0.3, channel_names[i], horizontalalignment='right')

        ax.set_axis_off()
        ax.set_xticks(np.arange(N))
        ax.xaxis.set_major_formatter(ticker.FuncFormatter(channel_formatter))
        fig.autofmt_xdate(rotation=x_tick_rot)
        ax.set_yticks(np.arange(N))
        ax.set_yticklabels(channel_names)
        ax.set_ybound([-0.5, N - 0.5])
        ax.set_xbound([-0.5, N - 1.5])

	#Make the tick-marks invisible:                                                                         
	for line in ax.xaxis.get_ticklines():
		line.set_markeredgewidth(0)

	for line in ax.yaxis.get_ticklines():
		line.set_markeredgewidth(0)

	ax.set_axis_off()

	if title is not None:
		ax.set_title(title)

	#The following produces the colorbar and sets the ticks                                                 
	if colorbar:
        #Set the ticks - if 0 is in the interval of values, set that, as well                               
        #as the maximal and minimal values:                                                                 
		if min_val < 0:
			ticks = [min_val, 0, max_val]
		#Otherwise - only set the minimal and maximal value:                                                
		else:
			ticks = [min_val, max_val]

        #This makes the colorbar:                                                                           
        cb = fig.colorbar(im, cax=ax_cb, orientation='horizontal',
                          cmap=cmap,
                          norm=im.norm,
                          boundaries=np.linspace(min_val, max_val, 256),
                          ticks=ticks,
                          format='%.2f')

   
	# Set the current figure active axis to be the top-one, which is the one                                
	# most likely to be operated on by users later on                                                       
	fig.sca(ax)

	return fig

   

def getNetworkWithin(dat, roiIndx):

        #Null the upper triangle, so that you don't get the redundant and
	#the diagonal values:                                                                            
	idx_null = triu_indices(dat.shape[0])
	dat[idx_null] = np.nan

        withInvals = dat[roiIndx,:][:,roiIndx]
        
        #Extract network values
        allNet=[]
        numROIs=roiIndx[1:]
        numStart=0
        while len(numROIs)>0:
            for jj in numROIs:
                allNet.append(dat[jj][roiIndx[numStart]])
            numStart+=1
            numROIs=numROIs[1:]
        return allNet

def getNetworkBtw(data, net1, net2):
    allBtw=data[net1,:][:,net2]
    allBtw=stats.nanmean(allBtw)
    return allBtw


def makeBarPlots(allMeansWithin, allSTDWithin, allMeansBtw, allSTDBtw, title, labels):
    N=len(allMeansWithin)
    ind = np.arange(N)  # the x locations for the groups
    width = 0.35       # the width of the bars

    fig = plt.figure()
    ax = fig.add_subplot(111)
    rects1 = ax.bar(ind, allMeansWithin, width, color='r', yerr=allSTDWithin)

    rects2 = ax.bar(ind+width, allMeansBtw, width, color='y', yerr=allSTDBtw)
    
    # add some
    ax.set_ylabel('Means')
    ax.set_title(title)
    ax.set_xticks(ind+width)
    ax.set_xticklabels( labels )

    ax.legend( (rects1[0], rects2[0]), ('Within', 'Between') )

    def autolabel(rects):
        # attach some text labels
        for rect in rects:
            height = rect.get_height()
            ax.text(rect.get_x()+rect.get_width()/2., 1.05*height, '%d'%int(height*100),
                ha='center', va='bottom')

    #autolabel(rects1)
    #autolabel(rects2)

    plt.show()


if __name__ == "__main__":

	# Close any opened plots
	plt.close('all')
    
	base_path = '/Volumes/Plata1/DorsalVentral/' # Change this to your path
	fmri_path = base_path + 'fmri/'
	fileName='CG_21runs_2012-01-30.pck'
	loadFile=fmri_path+'Results/' +fileName

	figSize=[10., 10.]
	# Load the data
	print 'Loading subject coherence and correlation dictionaries.'
	file=open(loadFile, 'r')
	 # First file loaded is coherence
	cohAll=pickle.load(file)
	# Second file loaded is correlation
	corrAll=pickle.load(file)
	roiNames=pickle.load(file)
	file.close()

	#Define the streams
	Ventral=[1,2,3, 5, 6, 7, 8]
	Dorsal=[10, 11, 12, 13, 14, 15]
	Lateral=[4, 9, 16]

	for sub in cohAll:
		print sub
		numRuns=cohAll[sub].shape[0]
		# Average over runs (the first dimension)
		coherAvg=np.mean(cohAll[sub][:], 0)
                coherSTD=np.std(cohAll[sub][:], 0)
		corrAvg=np.mean(corrAll[sub][:],0)
                corrSTD=np.std(corrAll[sub][:], 0)

		# Plot graph of coherence and correlation values
		fig1 = makePlot(coherAvg, roiNames, size=[10., 10.], color_anchor=0,
				title='Average Coherence Results over ' +str(numRuns) + ' runs for ' + sub, max_val=1, min_val=0)
                fig2=makePlot(coherSTD, roiNames, size=[10., 10.], color_anchor=0,
				title='Average Coherence STD over ' +str(numRuns) + ' runs for ' + sub)
		fig3=makePlot(corrAvg, roiNames, size=[10., 10.], color_anchor=0,
			      title='Average Correlation Results over ' +str(numRuns) + ' runs for ' + sub, max_val=1, min_val=0)
                fig4=makePlot(corrSTD, roiNames, size=[10., 10.], color_anchor=0,
			      title='Average Correlation STD over ' +str(numRuns) + ' runs for ' + sub)
		plt.show()

                #Fisher transform the data
                coherAvg_t = np.arctanh(coherAvg)
                corrAvg_t=np.arctanh(corrAvg)

                #replace all inf with nan
                ind = np.where(coherAvg_t == np.Infinity)
                coherAvg_t[ind] = np.nan
                ind = np.where(corrAvg_t == np.Infinity)
                corrAvg_t[ind] = np.nan
                
                # Get network averages
                lateralCoher=getNetworkWithin(coherAvg_t, Lateral)
                dorsalCoher=getNetworkWithin(coherAvg_t, Ventral)
                ventralCoher=getNetworkWithin(coherAvg_t, Dorsal)
                allMeansWithin=(np.mean(lateralCoher), np.mean(dorsalCoher), np.mean(ventralCoher))
                allSTDWithin=(np.std(lateralCoher), np.std(dorsalCoher), np.std(ventralCoher))

                latBtwCoher=getNetworkBtw(coherAvg_t, Lateral, Ventral+Dorsal)
                dorsBtwCoher=getNetworkBtw(coherAvg_t, Dorsal, Lateral+Ventral)
                ventBtwCoher=getNetworkBtw(coherAvg_t, Ventral, Dorsal+Lateral)

                allMeansBtw=(stats.nanmean(latBtwCoher), stats.nanmean(dorsBtwCoher), stats.nanmean(ventBtwCoher))
                allSTDBtw=(stats.nanstd(latBtwCoher), stats.nanstd(dorsBtwCoher), stats.nanstd(ventBtwCoher))
        
                # Make bar graph
                title='Mean Coherence by Network'; labels=('Lateral', 'Dorsal', 'Ventral')
                makeBarPlots(allMeansWithin, allSTDWithin, allMeansBtw, allSTDBtw, title, labels)

                


                

