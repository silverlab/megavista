#-----------------------------------------------------------------------------
# libraries
#-----------------------------------------------------------------------------
import os, string, popen2, re

#outside stuff
import numpy as np
from matplotlib import pyplot as plt
from matplotlib import mlab
from scipy import stats

#nipy stuff
import nitime as nt
import nitime.fmri.io as io
import nitime.analysis as nta
import nibabel as nib

#from my own code
import tuning_curve_fns as tcf
import util
map(reload,[tcf,util]) #reload things from my own code while debugging

#-----------------------------------------------------------------------------
# definitions
#-----------------------------------------------------------------------------
def load_sub_info(sub,mask_str_top,mask_type,loc_file):
    """ Load subject specific run information
    """
    if sub == 'EN2' and mask_str_top == 'allFFA_OFA_STS':
        mask_str = 'allFFA_OFA'
    else:
        mask_str = mask_str_top

    if sub == 'EN2' or sub == 'AM1' or sub == 'AM3':
        res = 'highSNR'
        if mask_type == 'reliable':
            mask_extra = 'rel_coords_mask'
        elif mask_type == 'all':
            mask_extra = 'mask'
        mask_extra2 = ''
    else:
        res = 'highRES'
        if mask_type == 'reliable':
            mask_extra = 'r_rel_coords_mask'
        elif mask_type == 'all':
            mask_extra = 'r_mask'
        mask_extra2 = '_r'


    #number of runs
    if sub == 'S07D1' or sub == 'EP2' or sub == 'S10D1':
        num_runs = 6
    else:
        num_runs = 7


    #directories
    if loc_file == 'afni_proc':
        dataDir = homeDir + 'Data/' + sub + '/faceattend_'+res+'/Analysis/afni_proc/'
        outDir = homeDir + 'Data/' + sub + '/faceattend_'+res+'/aggregate_data/'
        maskDir = homeDir + 'Data/' + sub + '/facespace_loc_'+res+'/aggregate_data/'
    elif loc_file == 'afni_proc_respprd':
        dataDir = homeDir + 'Data/' + sub + '/faceattend_'+res+'/Analysis/afni_proc_respprd/'
        outDir = homeDir + 'Data/' + sub + '/faceattend_'+res+'/aggregate_data_respprd/'
        maskDir = homeDir + 'Data/' + sub + '/facespace_loc_'+res+'/aggregate_data_respprd/'
        if sub == 'TC4' or sub == 'TC5':
            dataDir = homeDir + 'Data/' + sub + '/faceattend_highRES/Analysis/afni_proc/'
            outDir = homeDir + 'Data/' + sub + '/faceattend_highRES/aggregate_data/'

    elif loc_file == 'afni_proc_respprd_adapt':
        dataDir = homeDir + 'Data/' + sub + '/faceattend_'+res+'/Analysis/afni_proc_respprd/'
        outDir = homeDir + 'Data/' + sub + '/faceattend_'+res+'/aggregate_data_respprd_adapt/'
        maskDir = homeDir + 'Data/' + sub + '/facespace_loc_'+res+'/aggregate_data_respprd_adapt/'
        if sub == 'TC4' or sub == 'TC5':
            dataDir = homeDir + 'Data/' + sub + '/faceattend_highRES/Analysis/afni_proc/'
            outDir = homeDir + 'Data/' + sub + '/faceattend_highRES/aggregate_data/'

    return mask_str,mask_extra,mask_extra2,dataDir,outDir,maskDir,num_runs,res

def prep_and_load_data(dir,sub,run):
    """ Function that determines whether smoothed file exists; if not,makes it,
and then turns it into a nifti file and loads it properly.
    """

    
    fileout = '%spb03.%s.r0%s.blur' % (dir,sub,run)

    #if the blur file is gzipped, ungzip it
    if os.path.exists(fileout+'+orig.BRIK.gz'):

        print 'Unzipping files'
        command = 'gunzip %s' % (fileout+'+orig.BRIK.gz')
        os.system(command)

        command = 'gunzip %s' % (fileout+'+orig.HEAD.gz')
        os.system(command)
    
    #if there is no blur file, make it
    if not os.path.exists(fileout+'+orig.BRIK'):

        command = '3dmerge -1blur_fwhm 4.0 -doall -prefix %s %spb02.%s.r0%s.volreg+orig' %(fileout,dir,sub,run)
        print 'No smoothed file: '+fileout
        print command
        os.system(command)

    #if there is no nifti file, create it
    if not os.path.exists(fileout + '.nii'):

        print 'Making nifti version the file: ' + fileout
        command = '3dcopy %s+orig %s.nii' %(fileout,fileout)
        print command
        os.system(command)

    #return file name
    return fileout + '.nii',nib.load(fileout+'.nii')
        
    
def roi_timeseries_files(fileout,data_file,roi_file,sub):
    """ Function that extracts time-series from EPI in ROI of interest and
#saves it to a text file
    """

    #un-gzip data file if gzipped
    if os.path.exists(data_file + '.BRIK.gz'):
        print 'Unzipping file: ' + data_file
        command = 'gunzip %s*gz' % data_file
        os.system(command)

    #if sub is AM1, resample pb02 files since these are in weird resolutions
    if sub == 'AM1':
        if not os.path.exists(data_file[:-5] + '_r+orig.BRIK'):
            print 'Resampling data file for AM1'
            command = '3dresample -master %s -prefix %s_r+orig -inset %s' % (roi_file,data_file[:-5],data_file)
            os.system(command)
        data_file = data_file[:-5] + '_r+orig'

    #remove file if it already exists
    if os.path.exists(fileout):
        command = 'rm -f %s' % (fileout)
        #print command
        os.system(command)

    #print '*** REMEMBER need to add in function to mask masks by each other'
    #print '*** Should also modify to return size of each ROI'
    
    #extract data from roi mask in data fileout
    command = '3dmaskdump -o %s -mask %s %s' %(fileout,roi_file,data_file)
    #print command
    os.system(command)


def plot_connect_gaz(connect,conds,rois,method='',do_subtract=True,error=None):
    """ Make a  plot showing connectivity with PFC ROI
    """
    if do_subtract:
        att1_fix = connect[conds[0]] - connect[conds[2]] #att1 - fix
        att6_fix = connect[conds[1]] - connect[conds[2]] #att6 - fix
        label_1 = conds[0]+ '-'+ conds[2]
        label_2 = conds[1]+ '-'+ conds[2]
    else:
        att1_fix = connect[conds[0]]
        att6_fix = connect[conds[1]]
        if error is not None:
            att1_fix_error = error[conds[0]]
            att6_fix_error = error[conds[1]]
        label_1 = conds[0]
        label_2 = conds[1]
        

    plt.figure()
    plt.suptitle('MFG Connectivity Tuning, %s' % (method))

    x = range(len(rois[:6]))
    
    plt.subplot(2,2,1)
    plt.title(rois[6])
    if error == None:
        plt.plot(x,att1_fix[6,:6],label=label_1)
        plt.plot(x,att6_fix[6,:6],label=label_2)
    else:
        plt.errorbar(x,att1_fix[6,:6],label=label_1,yerr=att1_fix_error[6,:6])
        plt.errorbar(x,att6_fix[6,:6],label=label_2,yerr=att6_fix_error[6,:6])
    plt.ylabel('connectivity (%s)' % method)
    plt.xticks(x,rois[:6])
    plt.xlim((-1,len(rois[:6])))
    plt.xlabel('face region')
    plt.tick_params(labelsize = 10)

    plt.subplot(2,2,2)
    plt.title(rois[7])
    if error == None:
        plt.plot(x,att1_fix[7,:6],label=label_1)
        plt.plot(x,att6_fix[7,:6],label=label_2)
    else:
        plt.errorbar(x,att1_fix[7,:6],label=label_1,yerr=att1_fix_error[7,:6])
        plt.errorbar(x,att6_fix[7,:6],label=label_2,yerr=att6_fix_error[7,:6])
    plt.ylabel('connectivity (%s)' % method)
    plt.xticks(x,rois[:6])
    plt.xlim((-1,len(rois[:6])))
    plt.xlabel('face region')
    plt.tick_params(labelsize = 10)

    plt.legend(bbox_to_anchor = (0,-.2))
    plt.subplots_adjust(wspace = 0.4)
    plt.show()


    #make a face 1 vs face 6 plot
    plt.figure()
    plt.suptitle('Connectivity Tuning, %s' % method)

    plt.subplot(2,2,1)
    plt.title('ROI: %s' % rois[6])
    x = np.arange(1,3)
    width = 0.25
    valsA = [att1_fix[6,0], att1_fix[6,5]]
    valsB = [att6_fix[6,0], att6_fix[6,5]]
    yerrA = [att1_fix_error[6,0], att1_fix_error[6,5]]
    yerrB = [att6_fix_error[6,0], att6_fix_error[6,5]]
    plt.bar(x,valsA,width,color='w',yerr=yerrA,linewidth=2,ecolor='k',label='att1-fix')
    plt.bar(x+width,valsB,width,color='k',yerr=yerrB,linewidth=2,ecolor='k',label='att6-fix')
    plt.xlim((x[0]-0.7,x[-1]+2*width+0.7))
    plt.xlabel('ROI',fontsize = 10)
    plt.ylabel('connectivity',fontsize=10)
    plt.xticks(x + width,[rois[0],rois[5]])

    plt.subplot(2,2,2)
    plt.title('ROI: %s' % rois[7])
    x = np.arange(1,3)
    width = 0.25
    valsA = [att1_fix[7,0], att1_fix[7,5]]
    valsB = [att6_fix[7,0], att6_fix[7,5]]
    yerrA = [att1_fix_error[7,0], att1_fix_error[7,5]]
    yerrB = [att6_fix_error[7,0], att6_fix_error[7,5]]
    plt.bar(x,valsA,width,color='w',yerr=yerrA,linewidth=2,ecolor='k',label='att1-fix')
    plt.bar(x+width,valsB,width,color='k',yerr=yerrB,linewidth=2,ecolor='k',label='att6-fix')
    plt.xlim((x[0]-0.7,x[-1]+2*width+0.7))
    plt.xlabel('ROI',fontsize = 10)
    plt.ylabel('connectivity',fontsize=10)
    plt.xticks(x + width,[rois[0],rois[5]])

    plt.legend(bbox_to_anchor = (0,-0.2))
    plt.subplots_adjust(wspace = 0.4, hspace = 0.4)
    plt.show()


def plot_connect_PFC(connect,conds,rois,method='',do_subtract=True,error=None):
    """ Make a  plot showing connectivity with PFC ROI
    """
    if do_subtract:
        att1_fix = connect[conds[0]] - connect[conds[2]] #att1 - fix
        att6_fix = connect[conds[1]] - connect[conds[2]] #att6 - fix
        label_1 = conds[0]+ '-'+ conds[2]
        label_2 = conds[1]+ '-'+ conds[2]
    else:
        att1_fix = connect[conds[0]]
        att6_fix = connect[conds[1]]
        if error is not None:
            att1_fix_error = error[conds[0]]
            att6_fix_error = error[conds[1]]
        label_1 = conds[0]
        label_2 = conds[1]
        

    plt.figure()
    plt.suptitle('%s Connectivity Tuning, %s' % (rois[6],method))

    x = range(len(rois[:6]))
    if error == None:
        plt.plot(x,att1_fix[6,:6],label=label_1)
        plt.plot(x,att6_fix[6,:6],label=label_2)
    else:
        plt.errorbar(x,att1_fix[6,:6],label=label_1,yerr=att1_fix_error[6,:6])
        plt.errorbar(x,att6_fix[6,:6],label=label_2,yerr=att6_fix_error[6,:6])
    plt.ylabel('connectivity (%s)' % method)
    plt.xticks(x,rois[:6])
    plt.xlim((-1,len(rois[:6])))
    plt.xlabel('face region')
    plt.tick_params(labelsize = 10)

    plt.legend(loc='best')
    plt.show()



def tuning_plot(connect,conds,rois, method = '',do_subtract = True,error=None,
                stat1 = None, stat6 = None):
    """ Function that plots the connectivity tuning between rois
    """

    if do_subtract:
        att1_fix = connect[conds[0]] - connect[conds[2]] #att1 - fix
        att6_fix = connect[conds[1]] - connect[conds[2]] #att6 - fix
        label_1 = conds[0]+ '-'+ conds[2]
        label_2 = conds[1]+ '-'+ conds[2]
    else:
        att1_fix = connect[conds[0]]
        att6_fix = connect[conds[1]]
        if error is not None:
            att1_fix_error = error[conds[0]]
            att6_fix_error = error[conds[1]]
        label_1 = conds[0]
        label_2 = conds[1]
        

    plt.figure()
    plt.suptitle('Connectivity Tuning, %s' % method)

    plt.subplot(221)
    plt.title('Seed ROI: %s' % rois[0])
    x = range(len(rois[1:6]))
    if error == None:
        plt.plot(x,att1_fix[0,1:6],label=label_1)
        plt.plot(x,att6_fix[0,1:6],label=label_2)
    else:
        plt.errorbar(x,att1_fix[0,1:6],label=label_1,yerr=att1_fix_error[0,1:6])
        plt.errorbar(x,att6_fix[0,1:6],label=label_2,yerr=att6_fix_error[0,1:6])
    plt.ylabel('connectivity (%s)' % method)
    plt.xticks(range(len(rois[1:6])),rois[1:6])
    plt.xlim((-1,len(rois[1:6])))
    plt.ylim((-0.15,0.1))
    plt.xlabel('face region')
    plt.tick_params(labelsize = 10)

    #add stats
    if method == 'coh':
        yval = -.3
    else:
        yval = -.3

    if stat1 is not None:
        plt.text(x[0],yval,'%s r=%.03f, p=%.03f' %(conds[0],stat1[0][conds[0]],stat1[1][conds[0]]),
                 fontsize=8,color='r')
        plt.text(x[0],yval-.02,'%s b=%.03f, p=%.03f' %(conds[0],stat1[2][conds[0]],stat1[3][conds[0]]),
                 fontsize=8,color='r')
        plt.text(x[0],yval-.04,'%s r=%.03f, p=%.03f' %(conds[1],stat1[0][conds[1]],stat1[1][conds[1]]),
                 fontsize=8,color='r')
        plt.text(x[0],yval-.06,'%s b=%.03f, p=%.03f' %(conds[1],stat1[2][conds[1]],stat1[3][conds[1]]),
                 fontsize=8,color='r')

    
    plt.subplot(222)
    plt.title('Seed ROI: %s' % rois[5])
    if error == None:
        plt.plot(att1_fix[5,:5],label=label_1)
        plt.plot(att6_fix[5,:5],label=label_2)
    else:
        plt.errorbar(x,att1_fix[5,:5],label=label_1,yerr=att1_fix_error[5,:5])
        plt.errorbar(x,att6_fix[5,:5],label=label_2,yerr=att6_fix_error[5,:5])
    plt.ylabel('connectivity (%s)' % method)
    plt.xticks(range(len(rois[:5])),rois[:5])
    plt.xlim((-1,len(rois[:5])))
    plt.ylim((-0.15,0.1))
    plt.xlabel('face region')
    plt.tick_params(labelsize = 10)

    if stat6 is not None:
        plt.text(x[0],yval,'%s r=%.03f, p=%.03f' %(conds[0],stat6[0][conds[0]],stat6[1][conds[0]]),
                 fontsize=8,color='r')
        plt.text(x[0],yval-.02,'%s b=%.03f, p=%.03f' %(conds[0],stat6[2][conds[0]],stat6[3][conds[0]]),
                 fontsize=8,color='r')
        plt.text(x[0],yval-.04,'%s r=%.03f, p=%.03f' %(conds[1],stat6[0][conds[1]],stat6[1][conds[1]]),
                 fontsize=8,color='r')
        plt.text(x[0],yval-.06,'%s b=%.03f, p=%.03f' %(conds[1],stat6[2][conds[1]],stat6[3][conds[1]]),
                 fontsize=8,color='r')
            
    plt.subplots_adjust(wspace = 0.5)
    plt.legend(bbox_to_anchor = (0,-.2))
    plt.show()




def subtracted_mat_figure(data1,data2,name1='',name2='',method='',sub=''):
    """ Function that will plot raw values and difference of matrix sets
    """
    
    #plt.figure()
    nt.viz.drawmatrix_channels(data1-data2,channel_names = rois,size = [10.,10.],
                               color_anchor = 0)
    plt.title('%s, %s-%s %s' %(method,name1,name2,sub))

    plt.show()

    

#-----------------------------------------------------------------------------
# main script
#-----------------------------------------------------------------------------

# Inputs
mask_str_top = 'allface'
if mask_str_top == 'allaTemp':
    subjects = ['AM1','AM3','EN2','EP1','EP2','RM1','RM2','SS2','TC4','TC5','S08D1','S08D2','S10D1','S10D2','S11D1','S11D2']
elif mask_str_top == 'allFFA_OFA_STS':
    subjects =['AM1','AM3','EN2','EN3','EP1','EP2','RM1','RM2','SS2','SS3','TC4','TC5','S08D1','S08D2','S10D1','S10D2','S11D1','S11D2']# minus S07 due to high movement, bad ROI
else:
    subjects =['AM1','AM3','EN2','EN3','EP1','EP2','RM1','RM2','SS2','SS3','TC4','TC5','S08D1','S08D2','S10D1','S10D2','S11D1','S11D2'] # minus S07 due to high movement

mask_type = 'reliable' #mask_types = ['all','reliable']
loc_file = 'afni_proc_respprd_adapt' #loc_files = ['afni_proc', 'afni_proc_respprd']
val_type = 'beta' #beta or t_score
select_type = 'max' #max or z_score

#what to do
make_roi_timeseries_files = False
do_roi_connectivity = True
plot_individual_subs = False #need to do with do_roi_connectivity at the same time
do_group_roi_analysis = True #need to do do_roi_connectivity at the same time
do_weighted = False
do_windowing = True

#directories
homeDir = '/home/despo/cgratton/data/FaceSpace_loc/'
groupOutDir = homeDir + 'Group_Figs/'
topmaskDir = homeDir + 'Masks/face_areas/anatspace/'

#some helpful lists
conds =  ['ATTface1','ATTface6','fix']
face_list = ['face1','face2','face3','face4','face5','face6']

#rois to examine
#rois = face_list  + ['PFC'] #anatomical mask
#rois = face_list
#rois = face_list + ['LMFG_enh','LMFG_sup'] #gazzaley
rois = face_list + ['Zanto_LIFG','Zanto_LAngular'] #zanto

#data constants
#note: num_runs and f_lb calculated below
num_TRs = 150 #number of TRs in a single run
finalfix = 6 #number of end fixation points
TR = 2 #seconds in a TR
hrf_delay = 3 #number of TRs to delay HRF by (3 TRs = 6 seconds)
f_ub = 0.15 #frequency range of interest
NFFT = 25 #can't be much more than 1/2 time-series length

#initalize variables
corr_all = dict(); coh_all = dict()
vox_num = np.ones((len(subjects),len(rois))) * np.nan

for s,sub in enumerate(subjects):

    #load subject specific information
    mask_str,mask_extra,mask_extra2,dataDir,outDir,maskDir,num_runs,res = load_sub_info(sub,mask_str_top,mask_type,loc_file)

    #load stim information, sort by run
    block_info_temp = np.loadtxt(dataDir + 'stimuli/'+sub+'_all.1D')
    block_info = np.ones((num_runs,num_TRs,len(conds))) * np.nan
    start_ind = 0
    for nr in range(num_runs):
        block_info[nr,:,:] = block_info_temp[start_ind:start_ind+num_TRs,:3] #exclude final cond (cue period) if it exists
        start_ind += num_TRs

    #constants: ## NOTE, may vary by sub, glm type
    block_length = dict()
    if loc_file == 'afni_proc_respprd' or loc_file == 'afni_proc_respprd_adapt':
        block_length['ATTface1'] = 5
        block_length['ATTface6'] = 5
        block_length['fix'] = 5
    elif loc_file == 'afni_proc':
        block_length['ATTface1'] = 6
        block_length['ATTface6'] = 6
        block_length['fix'] = 6

    data = dict()
    for r,roi in enumerate(rois):

        if roi == 'PFC':
            roi_file = '%s%s/%s_%s%s.nii' %(topmaskDir,res,sub,roi,mask_extra2)
        elif roi == 'LMFG_enh' or roi == 'LMFG_sup' or roi == 'Zanto_LIFG' or roi == 'Zanto_LAngular':
            roi_file = '%sMasks/native_PFC/top50/%s_%s.nii' %(homeDir,roi,sub)
        else:
            roi_file = '%s%s_%s_%s_%s_%s_%s.nii' %(maskDir,roi,sub,mask_str,mask_extra,val_type,select_type)
        
        
        #load data from each run
        all_data = np.zeros((num_runs,num_TRs)) * np.nan
        #start_ind = 0
        for nr in range(num_runs):

            #file names
            fileout = '%s%s_timeseries_roi%s_run%s_%svox_mask%s.txt' %(outDir,sub,roi,nr+1,mask_type,mask_str_top)
            data_file = '%spb02.%s.r0%s.volreg+orig' % (dataDir,sub,nr+1)

            if make_roi_timeseries_files:

                #extract time series into text files
                roi_timeseries_files(fileout,data_file,roi_file,sub)

            if os.path.exists(fileout):
                #load data -- this is num of vox x num of TRs
                temp = np.loadtxt(fileout,usecols = range(3,num_TRs+3)) #first 3 vals=coords
                
                #convert data to percent signal change
                temp2 = nt.utils.percent_change(temp)
                
                #average over voxels and store; also store num of voxels
                #all_data[start_ind:start_ind+num_TRs] = stats.nanmean(temp2,axis=0)
                if temp2.size == 150: #single voxel large! don't average
                    all_data[nr,:] = temp2
                    vox_num[s,r] = 1 #should be the same across runs since same mask
                else:
                    all_data[nr,:] = np.mean(temp2,axis=0)
                    vox_num[s,r] = temp2.shape[0] #should be the same across runs since same mask
                
            else:
                print '>>>     File does not exist: ' + fileout
                #all_data[start_ind:start_ind+num_TRs] = np.nan
                all_data[nr,:] = np.nan
                vox_num[s,r] = 0
                
            #update index
            #start_ind += num_TRs

        #For debugging: plot whole run time-series
        #plt.figure()
        #plt.suptitle('%s roi:%s' %(sub,roi))
        #for nr in range(num_runs):
        #   plt.subplot(num_runs,1,nr+1)
        #   plt.plot(all_data[nr,:])
        #   plt.vlines(3,-10,10)
        #plt.show()

        #segment data from separate blocks
        ind = dict()
        for c,cond in enumerate(conds):

            #plt.figure()
            #plt.suptitle(cond)
            
            ind[cond] = dict()
            for nr in range(num_runs):
                ii = np.where(block_info[nr,:,c] == 1)[0]
                ii = ii + hrf_delay #add on a delay for HRF
                ind[cond][nr] = ii[np.where(ii < (num_TRs-finalfix+hrf_delay))[0]] #adjust for end of recording and final fixation period, store for future uses
                
                if r == 0 and nr == 0:
                    #for the first ROI, set up the structure
                    data[cond] = np.zeros((len(rois),num_runs,len(ind[cond][nr]))) * np.nan

                data[cond][r,nr,:] = all_data[nr,ind[cond][nr]]

                #plt.subplot(3,3,nr+1)
                #plt.plot(data[cond][r,nr,:],'k')

                #apply a hanning window to block lengths to minimize edge
                #artifacts
                if do_windowing:
                    count = 0
                    while count < (len(data[cond][r,nr,:])):
                        data[cond][r,nr,count:count+block_length[cond]] = mlab.window_hanning(data[cond][r,nr,count:count+block_length[cond]])
                        count += block_length[cond]
                        #plt.vlines(count,-3,3)


                #plt.plot(data[cond][r,nr,:],'r')
             
        del all_data

    #for debugging purposes, do some plotting
    #for cond in conds:
    #    plt.figure()
    #    plt.suptitle(cond)
    #    for nr in range(num_runs):
    #        plt.subplot(num_runs,1,nr+1)
    #        plt.plot(data[cond][:,nr,:].transpose())
    #    plt.show()
    #1/0

    if do_roi_connectivity:
        #roi x roi connectivity

        #calculate frequency lower bound
        f_lb = 1.0/(data['ATTface1'].shape[2]*TR)
        
        for cond in conds:

            #initialize shape of object, but only for first subject
            if s == 0:
                corr_all[cond] = np.zeros((len(subjects),num_runs,len(rois),len(rois))) * np.nan
                coh_all[cond] = np.zeros((len(subjects),num_runs,len(rois),len(rois))) * np.nan

            #plt.figure(); plt.suptitle(cond)
            for nr in range(num_runs):
                #initialize a time series object
                T = nt.TimeSeries(data[cond][:,nr,:],sampling_interval=TR)
                T.metadata['roi'] = rois

                #initialize a correlation analyzer
                Corr = nta.CorrelationAnalyzer(T)
                corr_all[cond][s,nr] = Corr.corrcoef    

                #initialize a coherence analyzer
                Coh = nta.CoherenceAnalyzer(T)
                Coh.method['NFFT'] = NFFT
                freq_ind = np.where((Coh.frequencies > f_lb) * (Coh.frequencies < f_ub))[0]
                coh_all[cond][s,nr] = np.mean(Coh.coherence[:,:,freq_ind],-1) #avg over frequencies
                
                #For debugging, lets look at some of the spectra
                #plt.subplot(num_runs,1,nr+1)
                #S_original = nta.SpectralAnalyzer(T)
                #plt.plot(S_original.psd[0],S_original.psd[1][0],label='Welch PSD')
                #plt.plot(S_original.spectrum_fourier[0],S_original.spectrum_fourier[1][0],label='FFT')
                #plt.plot(S_original.periodogram[0],S_original.periodogram[1][0],label='Periodogram')
                #plt.plot(S_original.spectrum_multi_taper[0],S_original.spectrum_multi_taper[1][0][0],label='Multi-taper')
                #plt.xlabel('Frequency (Hz)')
                #plt.ylabel('Power')
            #plt.legend()
            #plt.show()
            #1/0

    if plot_individual_subs:

        #Make some figures, CORRELATION
        #subtracted_mat_figure(corr_all[conds[0]][s],corr_all[conds[2]][s],name1=conds[0],name2=conds[2],method='Correlation',sub=sub)
        #subtracted_mat_figure(corr_all[conds[1]][s],corr_all[conds[2]][s],name1=conds[1],name2=conds[2],method='Correlation',sub=sub)
        subtracted_mat_figure(stats.nanmean(corr_all[conds[0]][s],axis=0),stats.nanmean(corr_all[conds[1]][s],axis=0),name1=conds[0],name2=conds[1],method='Correlation',sub=sub)

        #Make some figures, COHERENCE
        #subtracted_mat_figure(coh_all[conds[0]][s],coh_all[conds[2]][s],name1=conds[0],name2=conds[2],method='Coherence',sub=sub)
        #subtracted_mat_figure(coh_all[conds[1]][s],coh_all[conds[2]][s],name1=conds[1],name2=conds[2],method='Coherence',sub=sub)
        subtracted_mat_figure(stats.nanmean(coh_all[conds[0]][s],axis=0),stats.nanmean(coh_all[conds[1]][s],axis=0),name1=conds[0],name2=conds[1],method='Coherence',sub=sub)

        #Make a "tuning" figure
        #tuning_plot(corr_all,conds,rois,method='correlation')
        #tuning_plot(coh_all,conds,rois,method='coherence')



if do_group_roi_analysis:

    print ''
    print 'Group Analysis'

    #z-score values
    for cond in conds:

        corr_all[cond] = np.arctanh(corr_all[cond])
        coh_all[cond] = np.arctanh(coh_all[cond])

        #replace all inf with nan
        ind = np.where(corr_all[cond] == np.Infinity)
        corr_all[cond][ind] = np.nan
        ind = np.where(coh_all[cond] == np.Infinity)
        coh_all[cond][ind] = np.nan
        
    cond_new = ['ATTface1-fix','ATTface6-fix']
    coh_all_diff = dict(); corr_all_diff = dict()
    norm_type = 'raw' #diff or per_signal or raw

    if norm_type == 'diff':
        #do subtraction
        corr_all_diff[cond_new[0]] = corr_all['ATTface1'] - corr_all['fix']
        corr_all_diff[cond_new[1]] = corr_all['ATTface6'] - corr_all['fix']
        coh_all_diff[cond_new[0]] = coh_all['ATTface1'] - coh_all['fix']
        coh_all_diff[cond_new[1]] = coh_all['ATTface6'] - coh_all['fix']    
    elif norm_type == 'raw':
        #do nothing -> note, names are wrong here!
        corr_all_diff[cond_new[0]] = corr_all['ATTface1'] 
        corr_all_diff[cond_new[1]] = corr_all['ATTface6']
        coh_all_diff[cond_new[0]] = coh_all['ATTface1'] 
        coh_all_diff[cond_new[1]] = coh_all['ATTface6']
    elif norm_type == 'per_signal':
        #(a-b)/(a+b)
        corr_all_diff[cond_new[0]] = (corr_all['ATTface1'] - corr_all['fix'])/(corr_all['ATTface1'] + corr_all['fix'])
        corr_all_diff[cond_new[1]] = (corr_all['ATTface6'] - corr_all['fix'])/(corr_all['ATTface6'] + corr_all['fix'])
        coh_all_diff[cond_new[0]] = (coh_all['ATTface1'] - coh_all['fix'])/(coh_all['ATTface1'] + coh_all['fix'])
        coh_all_diff[cond_new[1]] = (coh_all['ATTface6'] - coh_all['fix'])/(coh_all['ATTface6'] + coh_all['fix'])
    else:
        1/0

    corr_all_diff_norm = dict()
    coh_all_diff_norm = dict()

    #average over subjects, find SE
    corr_group_mean = dict(); corr_group_se = dict()
    coh_group_mean = dict(); coh_group_se = dict()
    corr_group_mean_norm = dict(); corr_group_se_norm = dict()
    coh_group_mean_norm = dict(); coh_group_se_norm = dict()        

    r_1 = dict(); tr_1 = dict(); pr_1 = dict()
    b_1 = dict(); tb_1 = dict(); pb_1 = dict()
    r_6 = dict(); tr_6 = dict(); pr_6 = dict()
    b_6 = dict(); tb_6 = dict(); pb_6 = dict()
    methods = ['corr','coh']
    for method in methods:
        r_1[method] = dict(); tr_1[method] = dict(); pr_1[method] = dict()
        b_1[method] = dict(); tb_1[method] = dict(); pb_1[method] = dict()
        r_6[method] = dict(); tr_6[method] = dict(); pr_6[method] = dict()
        b_6[method] = dict(); tb_6[method] = dict(); pb_6[method] = dict()

    for cond in cond_new:

        #average over runs
        temp_corr = stats.nanmean(corr_all_diff[cond],axis = 1)
        temp_coh = stats.nanmean(coh_all_diff[cond],axis=1)

        #take means/ste across subjects
        if do_weighted:

            #for debugging: check that no subject dominates
            #plt.figure(); plt.suptitle(cond); n=1

            corr_group_mean[cond] = np.ones((len(rois),len(rois))) * np.nan
            corr_group_se[cond] = np.ones((len(rois),len(rois))) * np.nan
            coh_group_mean[cond] = np.ones((len(rois),len(rois))) * np.nan
            coh_group_se[cond] = np.ones((len(rois),len(rois))) * np.nan
            for r1 in range(len(rois)):
                for r2 in range(len(rois)):
                    v_vals = vox_num[:,r1] + vox_num[:,r2]
                    v_tot = np.nansum(v_vals)
                    v_weights = v_vals/v_tot
                    
                    #print 'weight max: %03f' %(np.nanmax(v_weights))
                    if np.nanmax(v_weights) > 0.30:
                        ind = np.where(v_weights == np.nanmax(v_weights))[0]
                        print '>> one sub contributing greater than 0.30, roiA: face%s, roiB face%s, sub: %s' %(r1+1,r2+1,subjects[ind])
                        
                        
                    corr_group_mean[cond][r1,r2],corr_group_se[cond][r1,r2] = util.weighted_stats(temp_corr[:,r1,r2],v_weights,v_tot)
                    coh_group_mean[cond][r1,r2],coh_group_se[cond][r1,r2] = util.weighted_stats(temp_coh[:,r1,r2],v_weights,v_tot)

                    #for debugging as above
                    #plt.subplot(len(rois),len(rois),n)
                    #plt.plot(v_weights)
                    #n+=1

            #plt.subplots_adjust(wspace = 0.5, hspace = 0.5)
            #plt.show()
            #1/0
 
        else:
            corr_group_mean[cond] = stats.nanmean(temp_corr,axis=0)
            coh_group_mean[cond] = stats.nanmean(temp_coh,axis=0)
            corr_group_se[cond] = util.nanste(temp_corr,0)
            coh_group_se[cond] = util.nanste(temp_coh,0)

        #for debugging
        #plt.figure(figsize=(20,10))
        #plt.suptitle('%s corr'%cond)
        #n=1
        #for r in range(corr_all_diff[cond].shape[1]):
        #    for s in range(corr_all_diff[cond].shape[0]):
        #        plt.subplot(corr_all_diff[cond].shape[1],corr_all_diff[cond].shape[0],n)
        #        plt.imshow(corr_all_diff[cond][s,r],interpolation='nearest',vmin=-1,vmax=1)
        #        n+=1
        #plt.subplots_adjust(wspace = 0.5, hspace = 0.5)
        #plt.show()            
        
        #for debugging
        #plt.figure()
        #plt.suptitle('%s corr, subs'%cond)
        #for s in range(temp_corr.shape[0]):
        #    plt.subplot(4,5,s+1)
        #    plt.imshow(temp_corr[s],interpolation='nearest',vmin=-1,vmax=1)
        #plt.subplot(4,5,20)
        #plt.imshow(corr_group_mean[cond],interpolation='nearest',vmin=-1,vmax=1)
        #plt.title('average')
        #plt.subplots_adjust(wspace=0.5,hspace=0.5)
        #plt.show()


        
        ## take means/ste after subtracting each subject's mean        
        corr_all_diff_norm[cond] = np.ones(temp_corr.shape) * np.nan
        coh_all_diff_norm[cond] = np.ones(temp_coh.shape) * np.nan
        for s in range(corr_all_diff[cond].shape[0]):
            corr_all_diff_norm[cond][s,:,:] = temp_corr[s] - stats.nanmean(temp_corr[s].flatten())
            coh_all_diff_norm[cond][s,:,:] = temp_coh[s] - stats.nanmean(temp_coh[s].flatten())
            # note: using full matrix, so std would be off but mean ok (diag is NaN)

        if do_weighted:
            1/0
            corr_group_mean_norm[cond] = np.ones((len(rois),len(rois))) * np.nan
            corr_group_se_norm[cond] = np.ones((len(rois),len(rois))) * np.nan
            coh_group_mean_norm[cond] = np.ones((len(rois),len(rois))) * np.nan
            coh_group_se_norm[cond] = np.ones((len(rois),len(rois))) * np.nan
            for r1 in range(len(rois)):
                for r2 in range(len(rois)):
                    v_vals = vox_num[:,r1] + vox_num[:,r2]
                    v_tot = np.nansum(v_vals)
                    v_weights = v_vals/v_tot
                    
                    corr_group_mean_norm[cond][r1,r2],corr_group_se_norm[cond][r1,r2] = util.weighted_stats(corr_all_diff_norm[cond][:,r1,r2],v_weights,v_tot)
                    coh_group_mean_norm[cond][r1,r2],coh_group_se_norm[cond][r1,r2] = util.weighted_stats(coh_all_diff_norm[cond][:,r1,r2],v_weights,v_tot)

        else:
            corr_group_mean_norm[cond] = stats.nanmean(corr_all_diff_norm[cond],axis=0)
            coh_group_mean_norm[cond] = stats.nanmean(coh_all_diff_norm[cond],axis=0)
            corr_group_se_norm[cond] = util.nanste(corr_all_diff_norm[cond],0)
            coh_group_se_norm[cond] = util.nanste(coh_all_diff_norm[cond],0)

        
        #determine linear trend in data
        r_1['corr'][cond],tr_1['corr'][cond],pr_1['corr'][cond] = util.linear_trend_r(temp_corr[:,0,1:6])
        b_1['corr'][cond],tb_1['corr'][cond],pb_1['corr'][cond] = util.linear_trend_b(temp_corr[:,0,1:6])
        r_6['corr'][cond],tr_6['corr'][cond],pr_6['corr'][cond] = util.linear_trend_r(temp_corr[:,5,0:5])
        b_6['corr'][cond],tb_6['corr'][cond],pb_6['corr'][cond] = util.linear_trend_b(temp_corr[:,5,0:5])

        r_1['coh'][cond],tr_1['coh'][cond],pr_1['coh'][cond] = util.linear_trend_r(temp_coh[:,0,1:6])
        b_1['coh'][cond],tb_1['coh'][cond],pb_1['coh'][cond] = util.linear_trend_b(temp_coh[:,0,1:6])
        r_6['coh'][cond],tr_6['coh'][cond],pr_6['coh'][cond] = util.linear_trend_r(temp_coh[:,5,0:5])
        b_6['coh'][cond],tb_6['coh'][cond],pb_6['coh'][cond] = util.linear_trend_b(temp_coh[:,5,0:5])
        


        #plot data
        nt.viz.drawmatrix_channels(corr_group_mean[cond],rois,
                                   size = [10.,10.],color_anchor=0)
        plt.title('%s correlations' %cond)
        plt.show()

        nt.viz.drawmatrix_channels(coh_group_mean[cond],rois,
                                   size = [10.,10.],color_anchor=0)
        plt.title('%s coherence' %cond)
        plt.show()
    

    #plot connectivity tuning functions
    tuning_plot(corr_group_mean,cond_new,rois,method='corr',
                do_subtract = False,error=corr_group_se,
                stat1 = [r_1['corr'],pr_1['corr'],b_1['corr'],pb_1['corr']],
                stat6 = [r_6['corr'],pr_6['corr'],b_6['corr'],pb_6['corr']])
    
    tuning_plot(coh_group_mean,cond_new,rois,method='coh',
                do_subtract = False,error=coh_group_se,
                stat1 = [r_1['coh'],pr_1['coh'],b_1['coh'],pb_1['coh']],
                stat6 = [r_6['coh'],pr_6['coh'],b_6['coh'],pb_6['coh']])

    tuning_plot(corr_group_mean_norm,cond_new,rois,method='corr_norm',
                do_subtract = False,error=corr_group_se_norm,
                stat1 = [r_1['corr'],pr_1['corr'],b_1['corr'],pb_1['corr']],
                stat6 = [r_6['corr'],pr_6['corr'],b_6['corr'],pb_6['corr']])
    
    tuning_plot(coh_group_mean_norm,cond_new,rois,method='coh_norm',
                do_subtract = False,error=coh_group_se_norm,
                stat1 = [r_1['coh'],pr_1['coh'],b_1['coh'],pb_1['coh']],
                stat6 = [r_6['coh'],pr_6['coh'],b_6['coh'],pb_6['coh']])



    if rois[-1] == 'PFC':
        #make a bar plot for connectivity with PFC ROI
        plot_connect_PFC(corr_group_mean, cond_new, rois, method='corr',
                         do_subtract = False, error = corr_group_se)
        plot_connect_PFC(coh_group_mean, cond_new, rois, method='coh',
                         do_subtract = False, error = coh_group_se)

        plot_connect_PFC(corr_group_mean_norm, cond_new, rois, method='corr_norm',
                         do_subtract = False, error = corr_group_se_norm)
        plot_connect_PFC(coh_group_mean_norm, cond_new, rois, method='coh_norm',
                         do_subtract = False, error = coh_group_se_norm)



    elif rois[-1] == 'LMFG_enh' or rois[-1] == 'LMFG_sup' or rois[-1] == 'Zanto_LIFG' or rois[-1] == 'Zanto_LAngular':
        plot_connect_gaz(corr_group_mean, cond_new, rois, method='corr',
                         do_subtract = False, error = corr_group_se)
        plot_connect_gaz(coh_group_mean, cond_new, rois, method='coh',
                         do_subtract = False, error = coh_group_se)


        plot_connect_gaz(corr_group_mean_norm, cond_new, rois, method='corr_norm',
                         do_subtract = False, error = corr_group_se_norm)
        plot_connect_gaz(coh_group_mean_norm, cond_new, rois, method='coh_norm',
                         do_subtract = False, error = coh_group_se_norm)
