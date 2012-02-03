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
	#idx_null = triu_indices(m.shape[0])
	#m[idx_null] = np.nan

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

def getNetworkWithin_test(in_d, roiIndx):

        dat=in_d.copy()
        #Null the upper triangle, so that you don't get the redundant and
	#the diagonal values:                                                                            
	idx_null = triu_indices(dat.shape[0])
	dat[idx_null] = np.nan
        
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
    
def getNetworkWithin(in_dat, roiIndx):

        m=in_dat.copy()
        #Null the upper triangle, so that you don't get the redundant and
	#the diagonal values:    
	idx_null = triu_indices(m.shape[0])
	m[idx_null] = np.nan

        #Extract network values
        withinVals = m[roiIndx,:][:,roiIndx]

        return withinVals
    
def getNetworkBtw(dataBtw, net1, net2):

    data_b=dataBtw.copy()
    allBtw=data_b[net1,:][:,net2]
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

    autolabel(rects1)
    autolabel(rects2)

    plt.show()

def get3NetworkAvg(data_t, titleName, roiNames, numRuns):
    #Define the streams
    Ventral=[1, 3, 11, 12, 13, 14]
    Dorsal=[2, 4, 5, 6, 7, 8, 9, 10]
    Lateral=[0, 1, 2, 3, 4]

    print 'Ventral rois: '+ str(roiNames[Ventral])
    print 'Dorsal rois: ' + str(roiNames[Dorsal])
    print 'Early Visual rois: '+ str(roiNames[Lateral])
    
    # Get network averages
    lateralCoher=getNetworkWithin(data_t, Lateral)
    dorsalCoher=getNetworkWithin(data_t, Ventral)
    ventralCoher=getNetworkWithin(data_t, Dorsal)
    #allMeansWithin=(stats.nanmean(lateralCoher.flat), stats.nanmean(dorsalCoher.flat), stats.nanmean(ventralCoher.flat))
    #allSTDWithin=(stats.nanstd(lateralCoher.flat), stats.nanstd(dorsalCoher.flat), stats.nanstd(ventralCoher.flat))
    allMeansWithin= (stats.nanmean(dorsalCoher.flat), stats.nanmean(ventralCoher.flat))
    allSTDWithin=( stats.nanstd(dorsalCoher.flat), stats.nanstd(ventralCoher.flat))

    latBtwCoher=getNetworkBtw(data_t, Lateral, Ventral+Dorsal)
    dorsBtwCoher=getNetworkBtw(data_t, Dorsal, Ventral)
    ventBtwCoher=getNetworkBtw(data_t, Ventral, Dorsal)

    #allMeansBtw=(stats.nanmean(latBtwCoher), stats.nanmean(dorsBtwCoher), stats.nanmean(ventBtwCoher))
    #allSTDBtw=(stats.nanstd(latBtwCoher), stats.nanstd(dorsBtwCoher), stats.nanstd(ventBtwCoher))
    # Just dorsal versus ventral 
    allMeansBtw=( stats.nanmean(dorsBtwCoher), stats.nanmean(ventBtwCoher))
    allSTDBtw=( stats.nanstd(dorsBtwCoher), stats.nanstd(ventBtwCoher))

    # Make bar graph
    title= titleName+ 'by Network for ' +sub+ ' for '+ str(numRuns)+' runs'; labels=( 'Dorsal', 'Ventral')
    makeBarPlots(allMeansWithin, allSTDWithin, allMeansBtw, allSTDBtw, title, labels)    

if __name__ == "__main__":

	# Close any opened plots
	plt.close('all')
    
	base_path = '/Volumes/Plata1/DorsalVentral/' # Change this to your path
	fmri_path = base_path + 'fmri/'
	fileName='CG&CHT&DCAallROIsOrderFix_matrplacebo1runs_2012-02-02.pck'
        condition='Placebo_leftFix'
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
        
	for sub in cohAll:
		print sub
		numRuns=cohAll[sub].shape[0]
		# Average over runs (the first dimension)
		coherAvg=np.mean(cohAll[sub][:], 0)
                coherSTD=np.std(cohAll[sub][:], 0)
		corrAvg=np.mean(corrAll[sub][:],0)
                corrSTD=np.std(corrAll[sub][:], 0)

		# Plot graph of coherence and correlation values
                '''
		fig1 = makePlot(coherAvg, roiNames, size=[10., 10.], color_anchor=0,
				title='Average ' +condition+  ' Coherence Results over ' +str(numRuns) + ' runs for ' + sub, max_val=1, min_val=0)
                fig2=makePlot(coherSTD, roiNames, size=[10., 10.], color_anchor=0,
				title='Average ' +condition+ ' Coherence STD over ' +str(numRuns) + ' runs for ' + sub)
		fig3=makePlot(corrAvg, roiNames, size=[10., 10.], color_anchor=0,
			      title='Average ' +condition+ ' Correlation Results over ' +str(numRuns) + ' runs for ' + sub, max_val=1, min_val=0)
                fig4=makePlot(corrSTD, roiNames, size=[10., 10.], color_anchor=0,
			      title='Average ' +condition+ ' Correlation STD over ' +str(numRuns) + ' runs for ' + sub)
		plt.show()
                '''
                #Fisher transform the data
                coherAvg_t = np.arctanh(coherAvg)
                corrAvg_t=np.arctanh(corrAvg)

                #replace all inf with nan
                ind = np.where(coherAvg_t == np.Infinity)
                coherAvg_t[ind] = np.nan
                ind = np.where(corrAvg_t == np.Infinity)
                corrAvg_t[ind] = np.nan
                
                #Plot data for 3 streams (btw for all)
                titleName=condition+" coherence "
                # get3NetworkAvg(coherAvg_t, titleName, roiNames, numRuns)
                titleName=condition+" correlation "
                #get3NetworkAvg(corrAvg_t, titleName, roiNames, numRuns)

                
                #Plot the data for 4 groups
                #Define the streams
                earlyVent=[1, 2, 3]
                earlyDors=[8, 9, 10]
                parietal=[11, 12, 13, 14, 15]
                objSel=[4,5,6]
                
                print 'Early Ventral rois: '+ str(roiNames[earlyVent])
                print 'Early Dorsal rois: ' + str(roiNames[earlyDors])
                print 'Parietal rois: '+ str(roiNames[parietal])
                print 'Object rois: '+ str(roiNames[objSel])
    
                # Get network averages
                earlyVentCoher=getNetworkWithin(coherAvg_t, earlyVent)
                earlyDorsCoher=getNetworkWithin(coherAvg_t, earlyDors)
                parietalCoher=getNetworkWithin(coherAvg_t, parietal)
                objSelCoher=getNetworkWithin(coherAvg_t, objSel)
         
                allMeansWithin= (stats.nanmean(earlyVentCoher.flat), stats.nanmean(earlyDorsCoher.flat), stats.nanmean(parietalCoher.flat),
                                 stats.nanmean(objSelCoher.flat))
                allSTDWithin=(stats.nanstd(earlyVentCoher.flat), stats.nanstd(earlyDorsCoher.flat), stats.nanstd(parietalCoher.flat),
                                 stats.nanstd(objSelCoher.flat))
                # Get network btw
                #Early Visual
                EVbtwED=coherAvg_t[earlyVent,:][:,earlyDors]; EVbtwEDavg=np.mean(EVbtwED); EVbtwEDstd=np.std(EVbtwED)
                EVbtwPar=coherAvg_t[earlyVent,:][:, parietal]; EVbtwParavg=np.mean(EVbtwPar); EVbtwParstd=np.std(EVbtwPar)
                EVbtwObjSel=coherAvg_t[earlyVent,:][:, objSel]; EVbtwObjSelavg=np.mean(EVbtwObjSel); EVbtwObjSelstd=np.std(EVbtwObjSel)

                # Early Dorsal
                EDbtwEV=coherAvg_t[earlyDors,:][:,earlyVent]; EDbtwEVavg=np.mean(EDbtwEV); EDbtwEVstd=np.std(EDbtwEV)
                EDbtwPar=coherAvg_t[earlyDors,:][:, parietal]; EDbtwParavg=np.mean(EDbtwPar); EDbtwParstd=np.std(EDbtwPar)
                EDbtwObjSel=coherAvg_t[earlyDors,:][:, objSel]; EDbtwObjSelavg=np.mean(EDbtwObjSel); EDbtwObjSelstd=np.std(EDbtwObjSel)

                # Parietal
                ParbtwEV=coherAvg_t[parietal,:][:,earlyVent]; ParbtwEVavg=np.mean(ParbtwEV); ParbtwEVstd=np.std(ParbtwEV)
                ParbtwED=coherAvg_t[parietal,:][:, earlyDors]; ParbtwEDavg=np.mean(ParbtwED); ParbtwEDstd=np.std(ParbtwED)
                ParbtwObjSel=coherAvg_t[parietal,:][:, objSel]; ParbtwObjSelavg=np.mean(ParbtwObjSel); ParbtwObjSelstd=np.std(ParbtwObjSel)

                # Object Selective
                ObjSelbtwEV=coherAvg_t[objSel,:][:,earlyVent]; ObjSelbtwEVavg=np.mean(ObjSelbtwEV); ObjSelbtwEVstd=np.std(ObjSelbtwEV)
                ObjSelbtwED=coherAvg_t[objSel,:][:, earlyDors]; ObjSelbtwEDavg=np.mean(ObjSelbtwED); ObjSelbtwEDstd=np.std(ObjSelbtwED)
                ObjSelbtwPar=coherAvg_t[objSel,:][:, parietal]; ObjSelbtwParavg=np.mean(ObjSelbtwPar); ObjSelbtwParstd=np.std(ObjSelbtwPar)


                allMeansBtw=([EVbtwEDavg, EDbtwEVavg, ParbtwEVavg, ObjSelbtwEVavg], [EVbtwParavg, EDbtwParavg, ParbtwEDavg, ObjSelbtwParavg],
                             [EVbtwObjSelavg, EDbtwObjSelavg, ParbtwObjSelavg,  ObjSelbtwEDavg])
                allSTDBtw=([EVbtwEDstd, EDbtwEVstd, ParbtwEVstd, ObjSelbtwEVstd], [EVbtwParstd, EDbtwParstd, ParbtwEDstd, ObjSelbtwParstd],
                             [EVbtwObjSelstd, EDbtwObjSelstd, ParbtwObjSelstd,  ObjSelbtwEDstd])
         
                # Make bar graph
                title= titleName+ 'by Network for ' +sub+ ' for '+ str(numRuns)+' runs'; labels=( 'Early Visual', 'Early Dorsal', 'Parietal', 'Object Selective')
                
                N=len(allMeansWithin)
                ind = np.arange(N)  # the x locations for the groups
                width = 0.15       # the width of the bars

                fig = plt.figure()
                ax = fig.add_subplot(111)
                rects1 = ax.bar(ind, allMeansWithin, width, color='r', yerr=allSTDWithin)

                rects2 = ax.bar(ind+width*1, allMeansBtw[0], width, color='y', yerr=allSTDBtw[0])
                rects3 = ax.bar(ind+width*2, allMeansBtw[1], width, color='g', yerr=allSTDBtw[1])
                rects4 = ax.bar(ind+width*3, allMeansBtw[2], width, color='b', yerr=allSTDBtw[2])
    
                # add some labels
                ax.set_ylabel('Means')
                ax.set_title(title)
                ax.set_xticks(ind+width*2)
                ax.set_xticklabels( labels )
                ax.legend((rects1[0], rects2[0], rects3[0], rects4[0]), ('Within', 'BtwEarlyVisual', 'BtwParietal', 'BtwObjectSel'))
                
                # Make a connection graph
                1/0
                fig04 = drawgraph_channels(cohAll[sub], roiNames, color_anchor=1)
