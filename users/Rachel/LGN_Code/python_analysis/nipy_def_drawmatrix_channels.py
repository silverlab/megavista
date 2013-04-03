#!/usr/bin/env python
# encoding: utf-8
"""
untitled.py

Created by Local Administrator on 2012-11-07.
Copyright (c) 2012 __MyCompanyName__. All rights reserved.
"""

import sys
import os


def drawmatrix_channels(in_m, channel_names=None, fig=None, x_tick_rot=0,
                        size=None, cmap=plt.cm.RdBu_r, colorbar=True,
                        color_anchor=None, title=None):
    """Creates a lower-triangle of the matrix of an nxn set of values. This is
    the typical format to show a symmetrical bivariate quantity (such as
    correlation or coherence between two different ROIs).

    Parameters
    ----------

    in_m: nxn array with values of relationships between two sets of rois or
    channels

    channel_names (optional): list of strings with the labels to be applied to
    the channels in the input. Defaults to '0','1','2', etc.

    fig (optional): a matplotlib figure

    cmap (optional): a matplotlib colormap to be used for displaying the values
    of the connections on the graph

    title : optional, string
      If given, title to be drawn atop the matrix.

    Returns
    -------

    fig: a figure object

    """
    N = in_m.shape[0]
    ind = np.arange(N)  # the evenly spaced plot indices

    def channel_formatter(x, pos=None):
        thisind = np.clip(int(x), 0, N - 1)
        return channel_names[thisind]

    if fig is None:
        fig = plt.figure()

    if size is not None:
        fig.set_figwidth(size[0])
        fig.set_figheight(size[1])

    w = fig.get_figwidth()
    h = fig.get_figheight()

    ax_im = fig.add_subplot(1, 1, 1)

    #If you want to draw the colorbar:
    if colorbar:
        divider = make_axes_locatable(ax_im)
        ax_cb = divider.new_vertical(size="20%", pad=0.2, pack_start=True)
        fig.add_axes(ax_cb)

    #Make a copy of the input, so that you don't make changes to the original
    #data provided
    m = in_m.copy()

    #Null the upper triangle, so that you don't get the redundant and the
    #diagonal values:
    idx_null = triu_indices(m.shape[0])
    m[idx_null] = np.nan

    #Extract the minimum and maximum values for scaling of the
    #colormap/colorbar:
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
                ax.text(-1, i + 0.3, channel_names[i],
                        horizontalalignment='right')

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




if __name__ == '__main__':
	main()

