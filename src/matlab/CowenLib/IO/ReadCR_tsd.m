function [eeg, sFreq] = ReadCR_tsd(fname, start_ts, end_ts, output_sFreq)
%
% Reads a CSC file (new NT format)and returns a tsd
%
% function tsd = ReadCR_tsd(cr)
%
%
% INPUT:
%       fname ... full filename of Cheetah_NT CSC*.dat file     
%  
%       output_sFreq = resample the data to be of the desired sampling frequency. Otherwise
%         return exactly what is passed in. If this is specified
% OUTPUT:
%
%       tsd of the csc data.
%       sampling rate of the data in c
%
% ADR 1999 called CR2EEG
% status PROMOTED
% version 1.0
% cowen Sat Jul  3 14:59:47 1999
% lipa  modified for NT   Jul 18 1999

% o Got rid of the diplay progress and rounded the timestamps
% o Fixed the dT to be in timestamps 
% o Added a dummy value to the end of cr.ts
% o Made the for look go to nBlocks and not nBlocks -1 
% cowen 2001
% o returns sampling freq.
%
%       ReadCR_nt returns 2 arrays and 1 double of the form...
%       ts = nrec x 1 array of the timestamps that start each block.
%       cr = nrec x 512 array of the data
%       sFreq = sampling frequency of the data in eeg

% cowen modified to use the partial load version of ReadCR_nt

if nargin >= 3    
    [ts,cr,sFreq] = ReadCR_partial_load(fname,start_ts, end_ts);  %  timestams ts are in 0.1 milliseconds units!!!!!
elseif nargin == 1
    [ts,cr,sFreq] = ReadCR_partial_load(fname);  %  timestams ts are in 0.1 milliseconds units!!!!!
elseif nargin == 2
    error('Invalid number of inputs')
end

if nargin < 4
    output_sFreq = [];
end

nBlocks = size(cr,1);
% Reuse cr to save space.
cr=reshape(cr',1,length(cr(:)));
blockSize = 512;
dT = 10000/sFreq; % in tstamps
TIME = zeros(size(cr));
ts = [ts;ts(end) + 512*dT];     
for iBlock = 1:(nBlocks)
  %DisplayProgress(iBlock, nBlocks-1);
  TIME((blockSize * (iBlock-1) + 1):(blockSize * iBlock)) = ...
      linspace(ts(iBlock), ts(iBlock+1) - dT, blockSize);
end
% Create the tsd object. Perhaps a waste.
pack % This is memory expensive

if isempty(output_sFreq)
    eeg = tsd(TIME', cr');
else
    st = TIME(1);
    et = TIME(end);
    n_out = round(((et-st)/10000)*output_sFreq);
    sFreq = output_sFreq;
    eeg  = tsd(linspace(st,et,n_out)', interp1(TIME, cr, linspace(st,et,n_out))');
end
