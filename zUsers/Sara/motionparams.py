#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#motionparams.py

"""This script takes compiles and plots mcflirt motion correction parameters
obtained by running motioncorrect.py.

100109 ASR wrote it
2011-Oct-18 RD modified from dicom2vista_graphonly.py
""" 

import os
import glob
import numpy as np
import sys
from matplotlib import pyplot as plt

if __name__ == "__main__": 
    #The full path to the session files is a command-line argument: 
    sess_dir = sys.argv[1]
    if sess_dir[-1]=='/': #If a trailing backslash has been input
        sess_dir=sess_dir[:-1]
    sess_name = os.path.split(sess_dir)[1]
    #switch to session directory:
    nifti_dir = sess_dir + '/' + sess_name + '_nifti'
    os.chdir(nifti_dir)
    print os.path.realpath(os.path.curdir)
    dir_list = np.array(os.listdir('.')) 
    motion_list = []
    for file in dir_list:
        if file.endswith('mcf.par'):
            motion_list.append(file)
    par_list = motion_list
    print par_list

    #make empty containers to add the motion params to, for plotting purposes:
    #Three rotation params:
    r1 = np.array([]) 
    r2 = np.array([])
    r3 = np.array([])
    #And three translations:
    t1 = np.array([])
    t2 = np.array([])
    t3 = np.array([])

    for this_par in par_list: 
        dt = dict(names = ('R1','R2','R3','T1','T2','T3'), 
                  formats = (np.float32,np.float32,np.float32,
                  np.float32,np.float32,np.float32))
        motion_params = np.loadtxt(this_par,dt)
            
        r1 = np.append(r1,motion_params['R1'])
        r2 = np.append(r2,motion_params['R2'])
        r3 = np.append(r3,motion_params['R3'])
        t1 = np.append(t1,motion_params['T1'])
        t2 = np.append(t2,motion_params['T2'])
        t3 = np.append(t3,motion_params['T3'])


    #note any places where translation motion is more than voxel size
    #get voxel size
    voxel_size = np.loadtxt('voxelinfo.txt')
    print voxel_size
    #voxel_size = np.array([1,1,1]) ##TEMPORARY for testing

    #make vectors for differences between adjacent TRs
    T1_differences = t1[1:] - t1[:-1]
    T2_differences = t2[1:] - t2[:-1]
    T3_differences = t3[1:] - t3[:-1]

    #Plot the motion params: 
    fig = plt.figure()
    ax1 = fig.add_subplot(2,1,1)
    ax1.plot(t1,'b-') #blue solid line
    ax1.plot(t2,'r-') #red solid line
    ax1.plot(t3,'g-') #green solid line
    #get current y axis min and max
    ymin, ymax = plt.ylim()
    #first look at dimension 1 for motion bigger than voxel size
    index = 0
    for movement in T1_differences:
        if movement>voxel_size[0]:
            #plot vertical line
            ax1.plot(np.array([index+0.5, index+0.5]),
                     np.array([ymin, ymax]),
                     'b--') #blue dashed line
        index += 1

    #then do the same for dimension 2
    index = 0
    for movement in T2_differences:
        if movement>voxel_size[1]:
            #plot vertical line
            ax1.plot(np.array([index+0.5, index+0.5]),
                     np.array([ymin, ymax]),
                     'r--') #red dashed line
        index += 1

    #and then for dimension 3
    index = 0
    for movement in T3_differences:
        if movement>voxel_size[2]:
            #plot vertical line
            ax1.plot(np.array([index+0.5, index+0.5]),
                     np.array([ymin, ymax]),
                     'g--') #green dashed line
        index += 1

    ax1.set_ylabel('Translation (mm)')
    ax2 = fig.add_subplot(2,1,2)
    ax2.plot(r1)
    ax2.plot(r2)
    ax2.plot(r3)
    ax2.set_ylabel('Rotation (rad)')
    ax2.set_xlabel('Time (TR)')
    fig.savefig(sess_name + '_motion_params.png')
    os.system('open ' + sess_name + '_motion_params.png')

    #Save the motion params:
    p = np.column_stack((t1,t2,t3,r1,r2,r3))
    np.savetxt('motionparams.txt',p)
    #p = np.genfromtxt('motionparams.txt')

