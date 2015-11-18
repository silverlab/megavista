#!/Library/Frameworks/Python.framework/Versions/Current/bin/python
#motionparams.py

"""This script takes compiles and plots mcflirt motion correction parameters
obtained by running motioncorrect.py.

100109 ASR wrote it
2011-Oct-18 RD modified from dicom2vista_graphonly.py
2015-Nov-09 SP modified to show in image where movement is greater than 
    voxel width and save epi and TR numbers for later use
2015-Nov-11 SP modified to combine translation and rotation info
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
    #voxel_size = np.array([1.,1.,1.]) ##TEMPORARY for testing
    print "Voxel size is %s" % voxel_size

    #need to find a way to read in brain dimensions from subject data
    #currently using average dimensions from this website
    #https://faculty.washington.edu/chudler/facts.html
    brain_dims = np.array([140.,93.,167.]) #TEMPORARY for testing
    print "Brain dimensions are %s" % brain_dims
    brain_dims = brain_dims/2

    #make vectors for differences between adjacent TRs
    T1_differences = np.abs(t1[1:] - t1[:-1])
    T2_differences = np.abs(t2[1:] - t2[:-1])
    T3_differences = np.abs(t3[1:] - t3[:-1])
    R1_differences = np.abs(r1[1:] - r1[:-1])
    R2_differences = np.abs(r2[1:] - r2[:-1])
    R3_differences = np.abs(r3[1:] - r3[:-1])

    delta_t1 = np.zeros(len(R1_differences))
    delta_t2 = np.zeros(len(R2_differences))
    delta_t3 = np.zeros(len(R3_differences))
    
    #functions for rotation matrixes around each axis
    def x_rotation(theta):
        sin_t = np.sin(theta)
        cos_t = np.cos(theta)
        x_rot_mat = np.array([[1, 0, 0],
                              [0, cos_t, -1*sin_t],
                              [0, sin_t, cos_t]])
        return x_rot_mat
    
    def y_rotation(theta):
        sin_t = np.sin(theta)
        cos_t = np.cos(theta)
        y_rot_mat = np.array([[cos_t, 0, sin_t],
                              [0, 1, 0],
                              [-1*sin_t, 0, cos_t]])
        return y_rot_mat
    
    def z_rotation(theta):
        sin_t = np.sin(theta)
        cos_t = np.cos(theta)
        z_rot_mat = np.array([[cos_t, -1*sin_t, 0],
                              [sin_t, cos_t, 0],
                              [0, 0, 1]])
        return z_rot_mat
    
    #and then combining all rotation matrices to get complete rotation
    def all_dir_rotation(theta_1,theta_2,theta_3):
        x_mat = x_rotation(theta_1)
        y_mat = y_rotation(theta_2)
        z_mat = z_rotation(theta_3)
        all_rot_mat = z_mat.dot(y_mat.dot(x_mat.dot(np.eye(3))))
        return all_rot_mat

    for i in range(len(R1_differences)):
        #find combined rotation matrix for all three rotations
        all_rot_mat = all_dir_rotation(R1_differences[i],R2_differences[i],
                                       R3_differences[i])
        #then multiply the rotation matrix by each axis of the brain
        new_x_brain_axis = all_rot_mat.dot(np.array([[brain_dims[0]],[0],[0]]))
        new_y_brain_axis = all_rot_mat.dot(np.array([[0],[brain_dims[1]],[0]]))
        new_z_brain_axis = all_rot_mat.dot(np.array([[0],[0],[brain_dims[2]]]))
        #then find the maximum change from that original axis in each direction
        delta_t1[i] = np.max(np.abs([brain_dims[0]-new_x_brain_axis[0],
                                     new_y_brain_axis[0], new_z_brain_axis[0]]))
        delta_t2[i] = np.max(np.abs([brain_dims[1]-new_y_brain_axis[1],
                                     new_x_brain_axis[1], new_z_brain_axis[1]]))
        delta_t3[i] = np.max(np.abs([brain_dims[2]-new_z_brain_axis[2],
                                     new_x_brain_axis[2], new_y_brain_axis[2]]))

    #and add translational change from rotations to raw translational changes
    total_T1_differences = T1_differences + delta_t1
    total_T2_differences = T2_differences + delta_t2
    total_T3_differences = T3_differences + delta_t3


    #finding out number of TRs per epi
    dicom_dir = sess_dir + '/' + sess_name + '_dicom'
    dir_list = np.array(os.listdir(dicom_dir))
    num_TRs_per_epi = []
    for folder in dir_list:
        if folder.startswith('epi'):
            dicom_files = os.listdir(dicom_dir + '/' + folder)
            num_TRs_per_epi.append(len(dicom_files))
    print "Number of TRs per epi %s" % num_TRs_per_epi

    #we will be storing which EPI and TR had too large of movements
    bad_timepoints = np.array([]).reshape(0,3)
    #column 1 = EPI number just BEFORE motion
    #column 2 = TR number of that EPI just BEFORE motion
    #column 3 = which translation dimension large motion is in

    #Plot the motion params:
    #SUBPLOT 1
    fig = plt.figure()
    ax1 = fig.add_subplot(3,1,1)
    ax1.plot(t1,'b-') #blue solid line
    ax1.plot(t2,'r-') #red solid line
    ax1.plot(t3,'g-') #green solid line
    #get current y axis min and max
    ymin, ymax = plt.ylim()
    ax1.set_ylabel('Translation (mm)')
    #first look at dimension 1 for motion bigger than half voxel size
    index = 0
    for movement in total_T1_differences:
        if movement>voxel_size[0]/2:
            #plot vertical line
            ax1.plot(np.array([index+0.5, index+0.5]),
                     np.array([ymin, ymax]),
                     'b--') #blue dashed line
            #figuring out which EPI and TR the movement are from
            run_index = 0;
            TR = index
            while TR>=0:
                TR = TR - int(num_TRs_per_epi[run_index])
                run_index += 1
            TR += num_TRs_per_epi[run_index-1]
            #switching from zero index to cardinal numbers
            TR = TR + 1
            epi = run_index
            text_string = 'EPI %d-TR %d' % (epi, TR)
            ax1.text(index+5, (11*ymin+ymax)/13, text_string,
                     fontsize=7, color='b')
            #save this as a bad timepoint
            bad_timepoints = np.vstack([bad_timepoints,[epi,TR,1]])
        index += 1

    #then do the same for dimension 2
    index = 0
    for movement in total_T2_differences:
        if movement>voxel_size[1]/2:
            #plot vertical line
            ax1.plot(np.array([index+0.5, index+0.5]),
                     np.array([ymin, ymax]),
                     'r--') #red dashed line
            #figuring out which EPI and TR the movement are from
            run_index = 0;
            TR = index
            while TR>=0:
                TR = TR - int(num_TRs_per_epi[run_index])
                run_index += 1
            TR += num_TRs_per_epi[run_index-1]
            #switching from zero index to cardinal numbers
            TR = TR + 1
            epi = run_index
            text_string = 'EPI %d-TR %d' % (epi, TR)
            ax1.text(index+5, (12*ymin+ymax)/13, text_string,
                     fontsize=7, color='r')
            #save this as a bad timepoint
            bad_timepoints = np.vstack([bad_timepoints,[epi,TR,2]])
        index += 1

    #and then for dimension 3
    index = 0
    for movement in total_T3_differences:
        if movement>voxel_size[2]/2:
            #plot vertical line
            ax1.plot(np.array([index+0.5, index+0.5]),
                     np.array([ymin, ymax]),
                     'g--') #green dashed line
            #figuring out which EPI and TR the movement are from
            run_index = 0;
            TR = index
            while TR>=0:
                TR = TR - int(num_TRs_per_epi[run_index])
                run_index += 1
            TR = TR + num_TRs_per_epi[run_index-1]
            #switching from zero index to cardinal numbers
            TR = TR + 1
            epi = run_index
            text_string = 'EPI %d-TR %d' % (epi, TR)
            ax1.text(index+5, (10*ymin+ymax)/13, text_string,
                     fontsize=7, color='g')
            #save this as a bad timepoint
            bad_timepoints = np.vstack([bad_timepoints,[epi,TR,3]])
        index += 1
            
    #SUBPLOT 2
    ax2 = fig.add_subplot(3,1,2)
    ax2.plot(total_T1_differences,'b.') #blue dots
    ax2.plot(total_T2_differences,'r.') #red dots
    ax2.plot(total_T3_differences,'g.') #green dots
    ax2.set_ylabel('Abs Max Translation (mm)')
    ax2.set_xlabel('Time (TR)')
    xmin, xmax = plt.xlim()
    #plot horizontal thresholds
    ax2.plot(np.array([xmin, xmax]),np.array([voxel_size[0]/2, voxel_size[0]/2]),
             'b--')
    ax2.plot(np.array([xmin, xmax]),np.array([voxel_size[1]/2, voxel_size[1]/2]),
             'r--')
    ax2.plot(np.array([xmin, xmax]),np.array([voxel_size[2]/2, voxel_size[2]/2]),
             'g--')

    #SUBPLOT 3
    ax3 = fig.add_subplot(3,1,3)
    ax3.plot(r1,'b-')
    ax3.plot(r2,'r-')
    ax3.plot(r3,'g-')
    ax3.set_ylabel('Rotation (rad)')
    ax3.set_xlabel('Time (TR)')
    fig.savefig(sess_name + '_motion_params.png')
    os.system('open ' + sess_name + '_motion_params.png')

    #Save the motion params:
    p = np.column_stack((t1,t2,t3,r1,r2,r3))
    np.savetxt('motionparams.txt',p)
    #p = np.genfromtxt('motionparams.txt')

    #Save the times where movement was too large:
    np.savetxt('largemovements.txt',bad_timepoints)
    #REMINDER:
    #column 1 = EPI number just BEFORE motion
    #column 2 = TR number of that EPI just BEFORE motion
    #column 3 = which translation dimension large motion is in

