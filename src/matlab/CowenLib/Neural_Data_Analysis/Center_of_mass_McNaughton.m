function [COM, C] = Center_of_mass_McNaughton(IN, dt_msec, msec_on_either_side, min_count);
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
%  C(cella, cellb, time) a cell by timebin matrix of the xcorrs for each cell pair.
% 
%  cowen
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
COM    = zeros(ncells)*nan;
[Rs Cs] = find(triu(ones(ncells))==0);
C      = zeros(ncells,ncells,n_bins)*nan;

for ii = 1:length(Rs)
    if ~isempty(IN{Rs(ii)}) & ~isempty(IN{Cs(ii)}) 
        [c, the_range]  = CrossCorrCount(IN{Rs(ii)},IN{Cs(ii)},dt_msec,n_bins);
        if sum(c) > min_count
            cm_val = Center_of_mass(c,the_range);
            %figure
            %bar(the_range,c)
            %hold on
            %line([cm_val cm_val],[0 10])

            COM(Rs(ii),Cs(ii)) = cm_val;
            C(Rs(ii),Cs(ii),:) = c;
            C(Cs(ii),Rs(ii),:) = c;
        end
    end
end

