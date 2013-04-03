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
import matplotlib.ticker as ticker
import matplotlib.colors as colors
from mpl_toolkits.axes_grid import make_axes_locatable


def display_tseries(tseries,vox_idx='all',fig=None,show_mean=True):
    """
    Display the voxel time-series of all voxels selected with vox_idx,
    along with the mean and sem.
    Currently, voxels must be along the zeroth dimension of TimeSeries object tseries
    """
    if fig is None:
        fig = plt.figure()

    TR = tseries.sampling_interval
    if vox_idx=='all':
        vox_tseries = tseries
    else:
        vox_tseries = ts.TimeSeries(tseries.data[vox_idx],sampling_interval=TR)

    fig = viz.plot_tseries(vox_tseries,fig)
    if show_mean:
        fig = viz.plot_tseries(ts.TimeSeries(np.mean(vox_tseries.data,0),
                                             sampling_interval=TR),
                               yerror=ts.TimeSeries(stats.sem(vox_tseries.data,0),
                                                    sampling_interval=TR),fig=fig,
                               error_alpha = 0.3,
                               linewidth=4,
                               color='r')
    return fig
    
def display_slices(im, min_val=None, max_val=None, cmap=None, fig=None):
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
        cax = ax.imshow(im[:,:,i_slice], vmin=min_val, vmax=max_val, cmap=cmap)
        
    # plt.subplots_adjust(bottom=0.1, right = 0.8, top=0.9)
    # cax = plt.axes([0.85, 0.1, 0.05, 0.8])
    # plt.colorbar(cax=cax)
    fig.colorbar(cax, ticks=[min_val, max_val], format='%.3f', orientation='horizontal')
    return fig


def display_matrix(m, xlabels=None, ylabels=None, cmap=None, color_anchor=None,
                      rotate_xlabels=True):
    """
    Display a full (eg. correlation-type) matrix using nitime viz machinery
    """
    if color_anchor == 0:
        min_val = np.nanmin(m)
        max_val = np.nanmax(m)
        bound = max(abs(max_val), abs(min_val))

    clim = np.array([-bound, bound])

    # Call to viz.draw_matrix (not exactly sure what axx is)
    axx = viz.draw_matrix(m, cmap=cmap, clim=clim)

    ax = axx.get_axes()

    # Label each of the cells with the row and the column
    if xlabels is not None:
        ax.set_xticks(xrange(len(xlabels)))
        ax.set_xticklabels(xlabels)
        if rotate_xlabels:
            rotation=30
            for label in ax.get_xticklabels():
                label.set_rotation(rotation)
                label.set_ha('left')

    if ylabels is not None:
        ax.set_yticks(xrange(len(ylabels)))
        ax.set_yticklabels(ylabels)

    #Make the tick-marks invisible:
    for line in ax.xaxis.get_ticklines():
        line.set_markeredgewidth(0)

    for line in ax.yaxis.get_ticklines():
        line.set_markeredgewidth(0)

    return axx


def display_matrix_INPROGRESS(m, xlabels=None, ylabels=None, fig=None,
                   cmap=None, colorbar=True, color_anchor=None):
    """
    Display a full (eg. correlation-type) matrix
    """
    if fig is None:
        fig = plt.figure()

    ax = fig.add_subplot(1,1,1)

    # Extract the minimum and maximum values for scaling of the
    # colormap/colorbar:
    min_val = np.nanmin(m)
    max_val = np.nanmax(m)

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

    # The call to imshow produces the matrix plot:
    im = ax.imshow(m, origin='upper', interpolation='nearest',
               vmin=color_min, vmax=color_max, cmap=cmap)

    # Label each of the cells with the row and the column
    if xlabels is not None:
        ax.set_xticks(xrange(len(xlabels)))
        ax.set_xticklabels(xlabels)

    if ylabels is not None:
        ax.set_yticks(xrange(len(ylabels)))
        ax.set_yticklabels(ylabels)

    #Make the tick-marks invisible:
    for line in ax.xaxis.get_ticklines():
        line.set_markeredgewidth(0)

    for line in ax.yaxis.get_ticklines():
        line.set_markeredgewidth(0)

    #The following produces the colorbar and sets the ticks
    if colorbar:
        None
        # plt.colorbar()

    # Set the current figure active axis to be the top-one, which is the one
    # most likely to be operated on by users later on
    fig.sca(ax)
    
    
if __name__ == '__main__':
    main()

