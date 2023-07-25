function [OUT, P, Fr, pure_coef] = Reactivation_EV(STM, STM_binsize_msec, options)
%function [OUT] = Reactivation_EV(STM, STM_binsize_msec)
% Based on Kudrimoti 2001 with modifications. It actually spits out the r
% value and not the r^2 so that negatives are not lost.
%
% INPUT: 
% STM - cell array: Pass in the binned spike train matrices (rows = time, col = cell) for
%       Each element of the cell array STM is the STM for each epoch.
%
% epochs: 1 = rest 1, 2 = maze (awake), 3 = Rest 2.
%
% STM_binsize_msec: Pass in the binsizes for each epoch as a 3 element matrix.
%
% Options:
%  if 'only_significant' is selected, then only include the significant correlations during maze running
%
% Cowen 2015
if nargin == 0
    % test it if the user passes in no input arguments.
    STM{2} = randn(1000,50); % random spiking...
    STM{1} = STM{2} + 5*randn(1000,50); % increse the scalar factor and reduce similarity.
    STM{3} = STM{2} + 0.20*randn(1000,50); % increse the scalar factor and reduce similarity.
    STM_binsize_msec = [20 20 20 ];
end

if nargin < 3
    options = [];
end
%
nCells = size(STM{1},2);
R = zeros((nCells^2-nCells)/2,3)*nan;
Fr = zeros((nCells^2-nCells)/2,2,3)*nan;
P = zeros((nCells^2-nCells)/2,3)*nan;

for ii = 1:3
    % Calculted correlations between all cell pairs for all epochs
    [R(:,ii), Fr(:,:,ii), P(:,ii)] = Corrcoef_with_rates(STM{ii},STM_binsize_msec(ii)/1000);
end
% idenify all zeros or nan values.
BADIX = isnan(sum(R,2)); 
% R values greater than 0.99 are artifactual (say 2 spikes at exactlay the
% same time on 2 electrodes.
BADIX = BADIX | max(abs(R),[],2) > 0.99;
    
if ismember('only_significant',options)
    % Only include the significant correlations during maze running -
    % ignore all else.
    BADIX = BADIX | P(:,2) > 0.05; % note the clever use of OR
end

R = R(~BADIX,:); P = P(~BADIX,:); Fr = Fr(~BADIX,:,:);
if Rows(R) < 30
    disp('Not enough data for calculation')
    OUT = [];
    return
end
% Compute the similarity between epochs
[tmp, p] = partialcorr(R(:,2:3),R(:,1));
OUT.rBC_A  = tmp(2);
OUT.rBC_A_p  = p(2);
[tmp, p] = partialcorr(R(:,1:2),R(:,3));
OUT.rAB_C  = tmp(2);
OUT.rAB_C_p  = p(2);
OUT.reactivation_strength = OUT.rBC_A - OUT.rAB_C; % This is the measure that will be used to judge the efficacy of this function.
OUT.n_comparisons = size(R,1);
% provide all other raw correlations.
[tmp, p] = corrcoef(R);
OUT.AllR.rAB = tmp(1,2); % This would be an estimate of preactivation
OUT.AllR.rBC = tmp(2,3);
OUT.AllR.rAC = tmp(1,3);
OUT.AllR.pAB = p(1,2); 
OUT.AllR.pBC = p(2,3);
OUT.AllR.pAC = p(1,3);

