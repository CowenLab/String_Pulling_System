function [OUT, P, Fr] = Remapping(STM, STM_binsize_msec, options)
%function [OUT] = Remapping(STM, STM_binsize_msec)
% Returns a score indicating how similar 2 time by cell matrices are to
% each other. (matchyness)
%
% INPUT: 
% STM - 2 element cell array of n time by n cell matrices: binned spike train matrices (rows = time, col = cell) for
%       Each element of the cell array STM is the STM for each epoch.
%
% STM_binsize_msec: Pass in the binsizes for each epoch as a 2 element matrix.
%
% Options:
%
% Cowen 2015
if nargin == 0
    % test it
    STM{1} = randn(1000,50);
    STM{2} = STM{1} + 0.01*randn(1000,50); % increse the scalar factor and reduce similarity.
    STM_binsize_msec = [20 20 ];
end

if nargin < 3
    options = [];
end
%
nCells = size(STM{1},2);
R = zeros((nCells^2-nCells)/2,2)*nan;
Fr = zeros((nCells^2-nCells)/2,2,2)*nan;
P = zeros((nCells^2-nCells)/2,2)*nan;
for ii = 1:2
    % Calculted correlations between all cell pairs for all epochs
    [R(:,ii), Fr(:,:,ii), P(:,ii)] = Corrcoef_with_rates(STM{ii},STM_binsize_msec(ii)/1000);
end
% idenify all zeros or nan values. Remove them
BADIX = isnan(sum(R,2)); 
R = R(~BADIX,:); P = P(~BADIX,:); Fr = Fr(~BADIX,:,:);
% Compute the similarity between epochs
tmp = corrcoef(R);
OUT.rAB  = tmp(2);
OUT.n_comparisons = size(R,1);

