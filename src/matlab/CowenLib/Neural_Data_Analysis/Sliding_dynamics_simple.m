function [SD]= Sliding_dynamics_simple(bigQ, window_size_bins, skip_size)
% function [SD]= Sliding_dynamics(bigQ, window_size_bins, skip_size, USE_NBCLUST, method, max_clusts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% nEffDim - from L Abbott - a measure of the compression or the number of
% effective dimensions that the STM matrix can be compressed.
% sparsity_level = degree of sparsity. Tie bigger the number, the less
% sparse (more dense).
%
% see cluster_demo_cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2022
%%%%%%%%%%%%%%%%%%%%%
minNeurons = 3;
SD.aborted_analysis = false;
%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    % Don't slide - just computer dynamics for the entire passed in
    % dataset.
    window_size_bins = Rows(bigQ);
end
% Clean A - get rid of unchanging columns or nan's in the COLUMNS (neurons). We will
% deal with zero sized rows later on.
IX = var(bigQ) == 0 | isnan(sum(bigQ));
bigQ = bigQ(:,~IX);

if Rows(bigQ) < window_size_bins || Cols(bigQ) < minNeurons
    disp(['Not enough bins or columns for the analysis Cols ' num2str(Cols(bigQ)) ' rows ' num2str(Rows(bigQ))])
    SD.aborted_analysis = true; PCA = [];
    SD.win_bins = [];
    return
end

SD.nCells = Cols(bigQ);

if nargin < 3 || isempty(skip_size)
    skip_size = round(window_size_bins/2); % XXX the older version had 4 default is to slide in 1/3 steps.
end

st =  1:skip_size:(Rows(bigQ)-window_size_bins + 1);
ed =  window_size_bins:skip_size:Rows(bigQ);
SD.win_bins = [st(:) ed(:)];
%
n_win_bins = Rows(SD.win_bins);

SD.nSamplesInCalculation = zeros(n_win_bins,1)*nan;

SD.nEffDim = zeros(n_win_bins,1)*nan;
SD.Rolls_Treves = zeros(n_win_bins,1)*nan;
SD.prop_in_first_3comp = zeros(n_win_bins,1)*nan;
SD.kurtosis = zeros(n_win_bins,1)*nan;
SD.prop_active = zeros(n_win_bins,1)*nan;
SD.CV = zeros(n_win_bins,1)*nan;
SD.mean_spikes_per_bin = zeros(n_win_bins,1)*nan;

tr = triu(ones(Cols(bigQ)),1);
TRIX = tr==1;
tr = triu(ones(window_size_bins),1);
TRIX_Time = tr==1;

% This is inefficient - probaby should skip bins. Probably should also
% restrict to cells with FR > 0.01 and < 3 to get rid of INs.
for iWin = 1:n_win_bins
    Q = bigQ(SD.win_bins(iWin,1):SD.win_bins(iWin,2),:);
    %     Qsc = Q - repmat(nanmean(Q),Rows(Q),1);
    if sum(Q(:) > 0)/length(Q(:)) < .001
        % done because some measures crash if there is just no activity.
        continue
    end
    [SD.nEffDim(iWin),nl] = n_effective_dimensions(Z_scores(Q));

    SD.prop_in_first_3comp(iWin) = sum(nl(1:3));
    SPA = Sparseness_measures(Q);
    SD.kurtosis(iWin) = nanmean(SPA.kurtosis);
    SD.prop_active(iWin) = nanmean(SPA.Prop_Active);
    SD.mean_spikes_per_bin(iWin) = mean(Q(:));
    if ~isempty(SPA.RT)
        SD.Rolls_Treves(iWin) = nanmean(SPA.RT);
        SD.CV(iWin) = nanmean(SPA.CV);
    else
        SD.Rolls_Treves(iWin) = nan;
        SD.CV(iWin) = nan;
    end
    SM = corrcoef(Q);
    SM(SM==1) = nan;
    SMv = SM(TRIX);
    SMv = SMv(~isnan(SMv));
    SD.R_matrix_mn_r(iWin) = nanmean(SMv);
    SD.R_matrix_md_r(iWin) = nanmedian(SMv);
    SD.R_matrix_sd_r(iWin) = nanstd(SMv);
    SD.R_matrix_skew_r(iWin) = skewness(SMv);
    %   SD.R_matrix_kurtosis_r(iWin) = kurtosis(SMv);
    SD.R_ratio_abv_below_pt3(iWin) = nansum(SMv > 0.3)/(nansum(SMv < 0.2) + eps);
    % Now for the S matrix
    SM = corrcoef(Q');
    SM(SM==1) = nan;
    try
        SMv = SM(TRIX_Time);
        SMv = SMv(~isnan(SMv));

        SD.S_matrix_mn_r(iWin) = nanmean(SMv);
        SD.S_matrix_md_r(iWin) = nanmedian(SMv);
        SD.S_matrix_sd_r(iWin) = nanstd(SMv);
        SD.S_matrix_skew_r(iWin) = skewness(SMv);
        %    SD.S_matrix_kurtosis_r(iWin) = kurtosis(SMv);
        SD.S_ratio_abv_below_pt8(iWin) = sum(SMv > 0.8)/(length(TRIX_Time)+ eps);
    end
end
