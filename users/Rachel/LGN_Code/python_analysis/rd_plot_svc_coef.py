#!/usr/bin/env python
# encoding: utf-8
"""
rd_plot_svc_coef.py

Created by Rachel on 2012-03-20.
"""

import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D


def main(svc):
	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')

	ax.plot(np.array([0,svc.coef_[0,0]]),np.array([0,svc.coef_[0,1]]),
		np.array([0,svc.coef_[0,2]]), '.-', markersize=12)
	ax.set_xlabel('X')
	ax.set_ylabel('Y')
	ax.set_zlabel('Z')
	ax.set_aspect('equal','datalim')
	plt.show()
	

if __name__ == '__main__':
	main(svc)