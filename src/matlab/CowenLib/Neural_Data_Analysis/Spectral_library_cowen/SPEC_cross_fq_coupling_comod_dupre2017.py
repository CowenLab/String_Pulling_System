"""
Wrapper for pactools by Dupre et al.. 2017. 

Comodulogram for interfacing with matlab by receiving and sending .mat files. 

TODO: Allow users to specify high fq range. Done automatically now. Retures 80 points between max low fq and sFreq/2

Cowen 2018
------------
Computes comodulograms with several methods.

A comodulogram shows the estimated PAC metric on a grid of frequency bands.
"""
#import numpy as np
import scipy.io as sio

from pactools import Comodulogram
n_jobs = 1

mat_contents = sio.loadmat('C:/Temp/cm_signal.mat')

fs = float(mat_contents['sFreq'][0])
n_surrogates = int(mat_contents['n_surrogates'][0])

signal = mat_contents['signal']
# NOTE: this is an incorrect use of range - they really want a list of frequencies.
low_fq_range = mat_contents['low_range'][0]
low_fq_width = 1.0  # Hz
method = mat_contents['method'][0]

###############################################################################
# To compute the comodulogram, we need to instanciate a `Comodulogram` object,
# then call the method `fit`. 

# Compute the comodulogram
print('%s... ' % (method, ))
if n_surrogates < 1:
    estimator = Comodulogram(fs=fs, low_fq_range=low_fq_range,
                             low_fq_width=low_fq_width, method=method,
                             progress_bar=False)
    estimator.fit(signal)
    M = {'CM': estimator.comod_, 'low_fq_range': estimator.low_fq_range , 'high_fq_range': estimator.high_fq_range , 'method': method }

else:
    estimator = Comodulogram(fs=fs, low_fq_range=low_fq_range,
                            low_fq_width=low_fq_width, method=method,
                            n_surrogates=n_surrogates, progress_bar=False,
                            n_jobs=n_jobs)
    estimator.fit(signal)
    M = {'CM': estimator.comod_,'CMz': estimator.comod_z_score_,'surrogate_max': estimator.surrogate_max_, 
                            'low_fq_range': estimator.low_fq_range , 
                            'high_fq_range': estimator.high_fq_range , 'method': method }
    



sio.savemat('C:/Temp/cm_out.mat',M)
