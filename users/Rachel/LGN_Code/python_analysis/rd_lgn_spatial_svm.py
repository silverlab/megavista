#!/usr/bin/env python
# encoding: utf-8
"""
rd_lgn_spatial_svm.py

Created by Rachel on 2012-03-06.
Modeled on plot_iris.py from scikits-learn
"""
# print __doc__

import numpy as np
import pylab as pl
from sklearn import svm, datasets
import scipy.io as sio

# import lgn data
data = sio.loadmat('lgnROI2_comGroupCoords_betaM-P_all_20120305.mat')
X = data['X']
Y = data['Y']
Y = np.squeeze(Y)

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
pl.set_cmap(pl.cm.Paired)

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
            pl.set_cmap(pl.cm.Paired)
            pl.contourf(xx[:,:,j], yy[:,:,j], Z[:,:,j], n_levels)
            pl.scatter(X[in_slice, 0], X[in_slice, 1], c=Y[in_slice])
    
    elif slice_dim == 1:
        if i==0:
            print 'slicing coronal'
        slices = np.unique(X[:,1])
        for j in np.arange(np.size(Z,1)):
            pl.subplot(3, 3, j + 1)   
            in_slice = X[:,1]==slices[j]

            # Plot the contour and the training points
            pl.set_cmap(pl.cm.Paired)
            pl.contourf(xx[:,j,:], zz[:,j,:], Z[:,j,:], n_levels)
            pl.scatter(X[in_slice, 0], X[in_slice, 2], c=Y[in_slice]) 

    pl.suptitle(titles[i])
    pl.show()


