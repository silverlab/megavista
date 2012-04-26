"""Generic utilities that may be needed by the other modules.
"""

#-----------------------------------------------------------------------------
# Imports
#-----------------------------------------------------------------------------

import numpy as np
import networkx as nx
import scipy.stats as stats
import os

#-----------------------------------------------------------------------------
# Functions
#-----------------------------------------------------------------------------
def unzip_hard(filename):
    """ Unzips a gziped file.  Stops if file does not exist, but check first if
#it is already unzipped.
    """

    if os.path.exists(filename):
        command = 'gunzip %s' % filename
        os.system(command)
        print 'Unzipping: ' + filename

    elif os.path.exists(filename[:-3]):
        print 'Already unzipped: ' + filename

    else:
        print 'Does not exist: ' + filename
        1/0

def unzip_easy(filename):
    """ Similar to unzip hard, but no foul if file does not exist.
    """

    if os.path.exists(filename):
        print 'Unzipping: ' + filename
        command = 'gunzip %s' % filename
        os.system(command)
    else:
        print 'Tried unzip, does not exist: ' + filename
        

def non_nan(array,array2=[],array3=[]):
    """ Return index of non-NAN values
    Can optionally take multiple arrays and find joint arrays that are not Nan
    """

    ind = np.where(np.isnan(array))[0]

    if len(array2)>0:
        ind2=  np.where(np.isnan(array2))[0]
    else:
        ind2 = []
    if len(array3)>0:
        ind3 = np.where(np.isnan(array3))[0]
    else:
        ind3 = []

    all_ind = range(len(array))
    good_ind = list(set(all_ind) - set(ind) - set(ind2) - set(ind3))
    
    return good_ind
    
def remove_previous_files(filename):
    """ This function removes a file if it exists and tells you about it.
    """

    if os.path.exists(filename):
        command = 'rm -f %s' %(filename)
        os.system(command)
        print 'File exists, removing: %s ' %(filename)

def remove_previous_files_hard(filename):
    """ This function removes a file (does not check if it exists)
    """

    command = 'rm -f %s' %(filename)
    os.system(command)
    print 'REMOVING: %s ' %(filename)


def linear_trend_b(data_temp):
    """ Function for determining whether there is a linear trend (using
    b-values or slopes) in the data """

    x = np.arange(data_temp.shape[1]) + 1 #values from 1 - 6
    b = np.zeros((data_temp.shape[0])) * np.nan

    for s in range(data_temp.shape[0]): #for each subject

        #find "good" (non-nan) indices
        ind = np.where(~np.isnan(data_temp[s,:]))[0]

        #do linear reg
        if len(ind) < 2: # tho note, 2 points = perfect line! 
            b[s] = np.nan
        else:
            (ar,br) = np.polyfit(x[ind],data_temp[s,ind],1)
            b[s] = ar #NOT br-- check past data on this!
            
    #find good indices
    ind = np.where(~np.isnan(b))[0]

    #do stats (unweighted!)
    b_mean = np.mean(b[ind])
    t_stat,p = stats.ttest_1samp(b[ind],0)

    return b_mean,t_stat,p

def linear_trend_r(data_temp):
    """ Function for determining whether there is a linear trend (using
    r-values) in the data
    ASSUMES: axis=0 is subs, axis=1 is faceconds"""

    x = np.arange(data_temp.shape[1]) + 1 #values from 1 - 6
    r = np.zeros((data_temp.shape[0])) * np.nan

    for s in range(data_temp.shape[0]):
        
        #find "good", non-nan, indices
        ind = np.where(~np.isnan(data_temp[s,:]))[0]
        if len(ind) < 3: #note: 2 points = perfect line! not included
            r[s] = np.nan
        else:
            r[s] = np.corrcoef(x[ind],data_temp[s,ind])[0,1]

    #find "good" indices
    ind = np.where(~np.isnan(r))[0]

    #transform into fisher values
    r_fisher = np.arctanh(r[ind])

    #do stats (unweighted!)
    r_fisher_mean = np.mean(r_fisher)
    t_stat,p = stats.ttest_1samp(r_fisher,0)
    #weighted stats
    #r_fisher_mean,r_fisher_se = util.weighted_stats(r_fisher,weights)
    #t_val = t_stat_weighted(r_fisher_mean,r_fisher_se)
    
    return np.mean(r[ind]),t_stat,p

    


def t_stat_weighted(avg_data,se_data):
    """ Function that computes a t-stat on weighted data.
    1 sample t-test.
    """

    t_score = avg_data/se_data

    return t_score
    
def weighted_stats(data,weights,v_tot = None):
    """ Function that takes data and weights and outputs mean and se 
    """

    #how to compute std:
    std_compute = 'Bland_Kerry' #standard or Bland_Kerry formula

    #find mean
    weighted_mean = np.nansum(data * weights)

    #find se
    var = np.zeros((data.shape[0])) * np.nan
    for s in range(data.shape[0]):
        var[s] = (data[s] - weighted_mean)**2

    if std_compute == 'standard':
        weighted_std = np.sqrt(np.nansum(var * weights))
    elif std_compute == 'Bland_Kerry':
        weighted_std = std_weighted_data(data,weights,weighted_mean,v_tot=v_tot) 

    #weighted_std2 = std_weighted_data(data,weights,weighted_mean,v_tot = v_tot) 
    #1/0

    weighted_se = weighted_std/np.sqrt(nanlen(var,0)-1) #correcting for bias w n-1

    return weighted_mean,weighted_se


def std_weighted_data(data,weights,weighted_mean,v_tot=None):
    """ Second version of doing weighting, taken from Bland,Kerry 1998
    (Clinical Review)
    """

    #check for "bad" points
    N = len(np.where(weights>0)[0])
    
    SS_weighted = np.nansum(data**2 * weights)/N
    if v_tot is not None:
        #do extra check here

        v_nums = weights * v_tot
        SS_weighted2 = np.nansum(v_nums * data**2)/(v_tot/N)
    else:
        print 'need v_tot'
        1/0
    
    correction_term = N * weighted_mean**2
    df = N - 1
    weighted_var = (SS_weighted2 - correction_term)/df
    weighted_std = np.sqrt(weighted_var)
    
    return weighted_std

    
def nanlen(array,axis):
    """ Function that counts the number of non-NAN's along an axis
    """

    #find all Nan's
    temp = np.isnan(array)
    temp2 = temp.sum(axis=axis)

    #want to find opposite, so subtract from "total"
    total = np.shape(array)[axis]
    return total - temp2

def nanste(array,axis):
    """ Function that computes standard error accounting for NaN's
    """

    err = stats.nanstd(array,axis=axis)/np.sqrt(nanlen(array,axis))

    return err
