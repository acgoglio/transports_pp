#
# Script to estimate mean and std dev of the transport
#
# imports
import matplotlib.pyplot as plt
import matplotlib as mpl # Palettes
import numpy as np
import netCDF4 as NC
import os
import sys
import warnings
#
warnings.filterwarnings("ignore") # Avoid warnings
#
from scipy.optimize import curve_fit
from scipy import stats
import collections
import pandas as pd
import csv
import math
import datetime
from datetime import date, timedelta
from datetime import datetime
from operator import itemgetter 
import plotly
from plotly import graph_objects as go # for bar plot
from mpl_toolkits.basemap import Basemap
from matplotlib.colors import LogNorm
from operator import itemgetter # to order lists
from statsmodels.distributions.empirical_distribution import ECDF # empirical distribution functions
# Specific libraries
from sklearn.utils import resample # To resample data
#
# 1 year time-serie
# Read the numbers
eas5_17 = NC.Dataset('/work/oda/ag15419/arc_link/eas5/exp_mrsp.sh_2017/diag_base.xml/tra_t_gb_ts.nc','r')
array_17=eas5_17.variables['transptx'][:,:,:,:]
array_17=np.squeeze(np.array(array_17))
# 
# Classical statistic (teo lim centrale)
mean_17=np.mean(array_17)
std1_17=np.std(array_17,ddof=1)
qdiffs_17=(array_17-mean_17)*(array_17-mean_17)
std1_man17=np.sqrt(np.sum(qdiffs_17)/(len(array_17)-1))
perc95_17=np.percentile(array_17,95)
meanstd1_17=std1_17/np.sqrt(len(array_17))
#
print ('---EAS5 2017---')
print ('mean(2017)=',mean_17)
#print ('std1(2017)=',std1_17)
#print ('std1(2017)=',std1_man17)
#print ('perc95(2017)=',perc95_17)
print ('std1 of the mean(2017)=',meanstd1_17)

# Bootstrap method (extract num_samp samples of lenght len_samp)
num_samp=100000
len_samp=180 # Days
print ('Bootstrap num samp,len samp respect.',num_samp,len_samp)
boot_means = []
for _ in range(num_samp):
    boot_sample = np.random.choice(array_17,replace = True, size = len_samp) # take a random sample each iteration
    boot_mean = np.mean(boot_sample)# calculate the mean for each iteration
    boot_means.append(boot_mean) # append the mean to boot_means
boot_means_np = np.array(boot_means) # transform it into a numpy array for calculation

boot_means = np.mean(boot_means_np)# bootstrapped sample means
boot_std = np.std(boot_means_np) # bootstrapped std

print ('boot_means',boot_means)
print ('boot_std',boot_std) 

print ('-------------------')
#
# Running-mean method 
run_len=180
print ('Running-mean sample len ',run_len)
run_means=np.convolve(array_17, np.ones(run_len)/run_len, mode='valid')
run_means_mean=np.mean(run_means)
run_means_std=np.std(run_means)
print ('run_means_mean ',run_means_mean)
print ('run_means_std ',run_means_std)

###################################3
# 3 years time-serie
#

eas5_161718 = NC.Dataset('/work/oda/ag15419/arc_link/eas5/exp_mrsp.sh_med_2016_2018/diag_base.xml/tra_t_gb_ts.nc','r')
array_161718=eas5_161718.variables['transptx'][:,:,:,:]
array_161718=np.squeeze(np.array(array_161718))
mean_161718=np.mean(array_161718)
std1_161718=np.std(array_161718,ddof=1)
perc95_161718=np.percentile(array_161718,95)
meanstd1_161718=std1_161718/np.sqrt(len(array_161718))

print ('---EAS5 2016-2018---')
print ('mean(2016-2018)=',mean_161718)
#print ('std1(2016-2018)=',std1_161718)
#print ('perc95(2016-18)=',perc95_161718)
print ('std1 of the mean(2016-2018)=',meanstd1_161718)

# Bootstrap method (extract num_samp samples of lenght len_samp)
num_samp=100000
len_samp=365
print ('Bootstrap num samp,len samp respect.',num_samp,len_samp)
var_stds=[]
var_means=[]
for num_samp in range(10000,100000+1,1000):
 #print ('Bootstrap num samp,len samp respect.',num_samp,len_samp)
 boot_means = []
 for _ in range(num_samp):
    boot_sample = np.random.choice(array_161718,replace = True, size = len_samp) # take a random sample each iteration
    boot_mean = np.mean(boot_sample)# calculate the mean for each iteration
    boot_means.append(boot_mean) # append the mean to boot_means
 boot_means_np = np.array(boot_means) # transform it into a numpy array for calculation

 boot_means = np.mean(boot_means_np)# bootstrapped sample means
 var_means.append(boot_means) 

 boot_std = np.std(boot_means_np) # bootstrapped std
 var_stds.append(boot_std)

print ('boot_means',num_samp,boot_means)
print ('boot_std',num_samp,boot_std)

#
# Running-mean method 
run_len=365
print ('Running-mean sample len ',run_len)
run_means=np.convolve(array_161718, np.ones(run_len)/run_len, mode='valid')
run_means_mean=np.mean(run_means)
run_means_std=np.std(run_means)
print ('run_means_mean ',run_means_mean)
print ('run_means_std ',run_means_std)

plot_flag=0
if plot_flag==1:
   # PLOT the values distributions
   kwargs = dict(alpha=0.5, bins=50)
   plt.hist(np.squeeze(array_17), **kwargs, color='r', label='Net GB transport 2017')
   plt.hist(np.squeeze(array_161718), **kwargs, color='b', label='Net GB transport 2016-2018')
   plt.gca().set(title='Net Gibraltar transport distributions', xlabel='Net transport [Sv]')
   plt.legend()
   plt.grid()
   plt.savefig('GB_transp_distrib.png')
   plt.clf()
   #plt.show()
   
   # Plot stds and means
   # Fig
   plt.figure(figsize=(20,10)) 
   plt.rc('font', size=16)
   plt.subplot(2,1,1)
   # Plot Title
   plt.title ('Bootstrap sensibility test')
   xval=range(100,100000,100)
   plt.plot(xval,var_means,'-',label='MEAN')
   plt.legend( loc='upper right',fontsize = 'large' )
   plt.grid ()
   plt.ylabel ('Values')
   plt.xlabel ('num of bootstrap yearly samples')
   # 
   plt.subplot(2,1,2)
   # Plot Title
   plt.plot(xval,var_stds,'-',label='STD')
   plt.legend( loc='lower right',fontsize = 'large' )
   plt.grid ()
   plt.ylabel ('Values')
   plt.xlabel ('num of bootstrap yearly samples')
   # Save and close 
   plt.savefig('bootstrap_test.png')
   plt.clf()
   #plt.show()

