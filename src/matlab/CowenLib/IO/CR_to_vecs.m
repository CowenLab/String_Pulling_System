function [TIME, DATA]= CR_to_vecs(cr, interp_data_sfreq)
%
% Converts the CR structure to a matrix
%
% function tsd = CR_to_matrix(cr)
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
%       matrix of the cr data where the first col is time
%
%

if nargin == 1
    interp_data_sfreq = 0;
end

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

DATA = cr.dd;

if interp_data_sfreq
    % Interpolate the data at the specified sampling frequency.
    n_points = (TIME(end) - TIME(1))/10000 * interp_data_sfreq;
    NEWTIME  = linspace(TIME(1), TIME(end), n_points);
    DATA     = interp1(TIME(:), DATA(:), NEWTIME);
    TIME     = NEWTIME;
end
