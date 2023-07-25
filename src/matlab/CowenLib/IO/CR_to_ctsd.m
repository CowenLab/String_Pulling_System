function eeg = CR_to_ctsd(cr,out_sFreq)
%
% Converts the CR structure to a ctsd (from peter lipa's ReadCR)
%
% function tsd = CR_to_ctsd(cr)
%
% ReadCR produces data in the format
%
%     struct CRfile with fields
%         CRfile.ts   : [NRecords,1] column vector of TimeStamps [0.1 msec] 
%         CRfile.sFreq: sampling Frequency [Hz]
%         CRfile.ddRecSize: length of data array per record 
%         CRfile.dd   : [Ndd,1] column vector of display data [?]
% 
%
% INPUT:
%       a structure cr of the form...
%       cr.ts = list of the timestamps that start each block.
%       cr.sFreq = sampling frequency
%       cr.ddRecSize = datapoints per block
%       cr.dd = the data
%       
% OUTPUT:
%
%       ctsd of the cr data.
%
% ADR 1999 called CR2EEG
% status PROMOTED
% version 1.0
%
% cowen Sat Jul  3 14:59:47 1999
% o Got rid of the diplay progress and rounded the timestamps
% o Fixed the dT to be in timestamps 
% o Added a dummy value to the end of cr.ts
% o Made the for look go to nBlocks and not nBlocks -1 


blockSize = 512;
nBlocks = length(cr.ts); % number of blocs in the entire cr record
dT = 10000/cr.sFreq; % in tstamps. Used to assign timestamps within each block

% Determine the output sampling frequency.
if nargin == 1
  % by default, make the output sFreq as close to the input sFreq as
  % possible.
  out_interval = round(dT); 
  disp(['Output will be sampled at ' num2str(10000/out_interval) ' Hz.'])
else  
  % Use a user specified output sampling frequency
  out_interval = 10000/out_sFreq;
end
	     
TIME = zeros(size(cr.dd));
cr.ts = [cr.ts;cr.ts(end) + 512*dT];

for iBlock = 1:(nBlocks)
  %DisplayProgress(iBlock, nBlocks-1);
  TIME((blockSize * (iBlock-1) + 1):(blockSize * iBlock)) = ...
      linspace(cr.ts(iBlock), cr.ts(iBlock+1) - dT, blockSize);
end
1
tic
X = interp1(TIME,cr.dd,TIME(1):out_interval:TIME(end),'linear');
toc
eeg = ctsd(TIME(1), out_interval, X');
