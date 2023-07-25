function [Bias,Bias_norm, C] = Bias_Skaggs(IN, dt_msec, msec_on_either_side, min_count);
% INPUT
%  cell array of timestamp vectors or ts objects
%  bin size in msec for the xcorr
%  msec on either side of the xcorr
%  min_count = minimum number of counts over all bins to consider this a valid xcorr.
% 
% OUTPUT
%  Bias a cell by cell matrix of the value of the bias for each cell pair. The upper diagonal
%  is set to nan as it's symmetric.
%
%  Bias_norm -- the normalized bias where each xcorr is normalized thus: L-R/L+R.
%
%  C(cella, cellb, time) a cell by timebin matrix of the xcorrs for each cell pair.
% 
if nargin < 4
    min_count = 0;
end


if isa(IN{1}, 'ts')
    IN = Ts_array_to_vectors(IN);
end
up = 0:dt_msec:msec_on_either_side;
the_range = [-up(end:-1:2) up];
n_bins = length(the_range);

ncells = length(IN);
Bias   = zeros(ncells)*nan;
[Rs Cs] = find(triu(ones(ncells))==0);
C      = zeros(ncells,ncells,n_bins)*nan;

for ii = 1:length(Rs)
    if ~isempty(IN{Rs(ii)}) & ~isempty(IN{Cs(ii)}) 
        [c, the_range]  = CrossCorrCount(IN{Rs(ii)},IN{Cs(ii)},dt_msec,n_bins);
        if sum(c) > min_count
            binsLR = (n_bins-1)/2;
            L = sum(c(1:binsLR));
            R = sum(c((binsLR+2):end));
            
            Bias(Rs(ii),Cs(ii)) = R-L;
            Bias_norm(Rs(ii),Cs(ii)) = (R-L)/(R+L);
            C(Rs(ii),Cs(ii),:)  = c;
            C(Cs(ii),Rs(ii),:)  = c;
        end
    end
end

