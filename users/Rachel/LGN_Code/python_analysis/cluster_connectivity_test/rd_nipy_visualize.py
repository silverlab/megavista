#!/usr/bin/env python
# encoding: utf-8
"""
visualize.py

Created by Rachel on 2012-04-18.
"""

import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats

import nitime.timeseries as ts
import nitime.viz as viz


def display_tseries(tseries,vox_idx,fig=None):
    """
    Display the voxel time-series
    Currently, voxels must be along the zeroth dimension
    """
    if fig is None:
        fig = plt.figure()

    TR = tseries.sampling_interval
    vox_tseries = ts.TimeSeries(tseries.data[vox_idx],sampling_interval=TR)

    fig = viz.plot_tseries(vox_tseries,fig)
    fig = viz.plot_tseries(ts.TimeSeries(np.mean(vox_tseries.data,0),
                                         sampling_interval=TR),
                           yerror=ts.TimeSeries(stats.sem(vox_tseries.data,0),
                                                sampling_interval=TR),fig=fig,
                           error_alpha = 0.3,ylabel='% signal change',
                           linewidth=4,
                           color='r')
    return fig
    
def display_slices(im, val_min=None, val_max=None, fig=None):
    """
    Display slices from a 3d image
    Assume last dimensino is the slice dimension
    """
    if fig is None:
	fig = plt.figure()
	
    n_slices = im.shape[-1]
    n_cols = np.ceil(np.sqrt(n_slices))
    n_rows = np.ceil(n_slices/n_cols)
    
    for i_slice in xrange(n_slices):
        ax = fig.add_subplot(n_rows, n_cols, i_slice)
	ax.set_axis_off()
	plt.imshow(im[:,:,i_slice], vmin=val_min, vmax=val_max)
	    
    return fig
    
    

if __name__ == '__main__':
	main()

