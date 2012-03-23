#!/usr/bin/env python
# encoding: utf-8
"""
rd_lgn_spatial_svm.py

Created by Rachel on 2012-03-06.
Modeled on plot_iris.py from scikits-learn
"""
# print __doc__

import glob
import numpy as np
import matplotlib.pylab as pl
from sklearn import svm, datasets
import scipy.io as sio
import datetime


def main():
    hemi = 1
    prop = 0.5
    varthresh = 0
    savefig = 1

    # file i/o
    file_base = 'lgnROI{}_comVoxGroupCoords_'.format(hemi)
    analysis_extension = 'betaM-P_prop{}_varThresh{:0^3}'.format(
        int(prop*100), int(varthresh*1000))
    data_path = glob.glob(file_base + analysis_extension + '*')[0]

    # import lgn data
    data = sio.loadmat(data_path)
    X = data['voxCoords']
    Y = data['voxGroups']
    Y = np.squeeze(Y)

    colors = np.array([[220, 20, 60],[0, 0, 205]])
    colors = colors/255.0
    cols = np.zeros((np.size(Y),3))
    for c in np.arange(np.size(Y)):
        cols[c,] = colors[Y[c]-1,]

    # we create an instance of SVM and fit out data. We do not scale our
    # data since we want to plot the support vectors
    C = 1  # SVM regularization parameter
    lin_svc = svm.SVC(kernel='linear', C=C).fit(X, Y)
    rbf_svc = svm.SVC(kernel='rbf', gamma=0.7, C=C).fit(X, Y)
    poly3_svc = svm.SVC(kernel='poly', degree=3, C=C).fit(X, Y)
    poly2_svc = svm.SVC(kernel='poly', degree=2, C=C).fit(X, Y)


    # create a mesh to plot in
    x_min, x_max = X[:, 0].min(), X[:, 0].max() + 1
    y_min, y_max = X[:, 1].min(), X[:, 1].max() + 1
    z_min, z_max = X[:, 2].min(), X[:, 2].max() + 1

    # make 3 3D meshgrid matrices. 3rd dimension is the z (inplane slice) dimension
    xx, yy, zz = np.mgrid[x_min:x_max, y_min:y_max, z_min:z_max] # add :30j to make 30 equally spaced points

    # title for the plots
    titles = ['SVC with linear kernel',
              'SVC with RBF kernel',
              'SVC with polynomial (degree 3) kernel',
              'SVC with polynomial (degree 2) kernel']

    # set plot parameters
    """
    n_levels is the number of contour levels. eg. 1 draws 1 contour
    slice_dim is whether slices will be by y (coronal, slice_dime=1) 
              or z (axial, slice_dim=2)
    """
    n_levels = 1
    slice_dim = 1
    pl.set_cmap(pl.cm.RdBu)
    # turn interactive mode on, so that pl.show() won't wait for the figure to be closed before continuing
    # pl.ion()

    for i, clf in enumerate((lin_svc, rbf_svc, poly3_svc, poly2_svc)):
        # Plot the decision boundary. For that, we will asign a color to each
        # point in the mesh [x_min, m_max]x[y_min, y_max].
        fig = pl.figure()
        Z = clf.predict(np.c_[xx.ravel(), yy.ravel(), zz.ravel()])

        # Put the result into a color plot
        Z = Z.reshape(xx.shape)

        if slice_dim == 2:
            if i==0:
                print 'slicing axial'
            slices = np.unique(X[:,2])
            for j in np.arange(np.size(Z,2)):
                pl.subplot(2, 3, j + 1)   
                in_slice = X[:,2]==slices[j]
 
                # Plot the contour and the training points
                pl.contourf(xx[:,:,j], yy[:,:,j], Z[:,:,j], n_levels)
                pl.scatter(X[in_slice, 0], X[in_slice, 1], c=cols[in_slice,])
    
        elif slice_dim == 1:
            if i==0:
                print 'slicing coronal'
            slices = np.unique(X[:,1])
            for j in np.arange(np.size(Z,1)):
                pl.subplot(3, 4, j + 1)   
                in_slice = X[:,1]==slices[j]

                # Plot the contour and the training points
                pl.contourf(xx[:,j,:], zz[:,j,:], Z[:,j,:], n_levels)
                pl.scatter(X[in_slice, 0], X[in_slice, 2], c=cols[in_slice,]) 

        pl.suptitle(titles[i])
        pl.show()
        
        if i==0 and savefig:
            print 'saving fig'
            pl.savefig('figures/lgnROI{}MapCoronal_spatialSVMLin_{}_{:%Y%m%d}.png'.format(
            hemi, analysis_extension, datetime.datetime.today()))

    return lin_svc


if __name__ == '__main__':
    main()
    