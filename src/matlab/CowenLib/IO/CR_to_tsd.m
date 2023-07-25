function eeg = CR_to_tsd(cr)
%
% Converts the CR structure to a tsd (from peter lipa's ReadCR)
%
% function tsd = CR_to_tsd(cr)
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
%       tsd of the cr data.
%
% ADR 1999 called CR2EEG
% status PROMOTED
% version 1.0
% cowen Sat Jul  3 14:59:47 1999
% o Got rid of the diplay progress and rounded the timestamps
% o Fixed the dT to be in timestamps 
% o Added a dummy value to the end of cr.ts
% o Made the for look go to nBlocks and not nBlocks -1 
% See CR2CTSD -- dave's code


blockSize = 512;
nBlocks = length(cr.ts);
dT = 10000/cr.sFreq; % in tstamps

TIME = zeros(size(cr.dd));
cr.ts = [cr.ts;cr.ts(end) + 512*dT];

for iBlock = 1:(nBlocks)
  %DisplayProgress(iBlock, nBlocks-1);
  TIME((blockSize * (iBlock-1) + 1):(blockSize * iBlock)) = ...
      linspace(cr.ts(iBlock), cr.ts(iBlock+1) - dT, blockSize);
end

eeg = tsd(TIME, cr.dd);
