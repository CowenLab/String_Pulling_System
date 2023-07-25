function [SD,PCA]= Sliding_dynamics(bigQ, window_size_bins, skip_size, USE_NBCLUST, method, max_clusts)
% function [SD,PCA]= Sliding_dynamics(bigQ, window_size_bins, skip_size, USE_NBCLUST, method, max_clusts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% nEffDim - from L Abbott - a measure of the compression or the number of
% effective dimensions that the STM matrix can be compressed.
% sparsity_level = degree of sparsity. Tie bigger the number, the less
% sparse (more dense).
%
% see cluster_demo_cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2015
%%%%%%%%%%%%%%%%%%%%%
if nargin < 6
    max_clusts = 45;
end
minNeurons = 3;

SD.nKlusts = 2:max_clusts; % XXX went from 45 to 65 -- I had it at one for the low end and this may have screwed things up.
min_cluster_members = 3;
SD.aborted_analysis = false;
%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    % Don't slide - just computer dynamics for the entire passed in
    % dataset.
    window_size_bins = Rows(bigQ);
end
if nargin < 4
    USE_NBCLUST = false;
end
if nargin < 5
    %                method = 'ward';  % This does not work well in matlab but it
    %          does in NbClust???/
    method = 'single';
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

SD.k_of_min_chi2 = zeros(n_win_bins,1)*nan;
SD.k_from_evalclusters_linkage_sil = zeros(n_win_bins,1)*nan;
% SD.k_from_evalclusters_linkage_stdrdized_sil = zeros(n_win_bins,1)*nan;
SD.k_of_NbClust = zeros(n_win_bins,1)*nan; % ths can take a long time to compoute.
% SD.k_of_max_scaled_entropy = zeros(n_win_bins,1)*nan; % not a good measure.
SD.k_of_max_nBinsGreater2 = zeros(n_win_bins,1)*nan;
% SD.k_of_max_CV_Hist_of_k = zeros(n_win_bins,1)*nan; % not a good measure.
SD.k_nBinsGreater2_linkage = zeros(n_win_bins,1)*nan;
SD.k_nBins2InRow_linkage = zeros(n_win_bins,1)*nan;
SD.k_from_cutoff_1_linkage = zeros(n_win_bins,1)*nan;

SD.chi2_of_k_linkage = zeros(n_win_bins,1)*nan;
SD.Cophenetic_CC = zeros(n_win_bins,1)*nan;

SD.State_Transition_Matrix = cell(n_win_bins,1);

SD.entropy = zeros(n_win_bins,length(SD.nKlusts))*nan;
SD.scaled_entropy = zeros(n_win_bins,length(SD.nKlusts))*nan;
SD.CV_Hist_of_k = zeros(n_win_bins,length(SD.nKlusts))*nan;
SD.nBinsGreater2 = zeros(n_win_bins,length(SD.nKlusts))*nan;
SD.chi2_of_k = zeros(n_win_bins,length(SD.nKlusts))*nan;


SD.R_matrix_mn_r = zeros(n_win_bins,1)*nan;
SD.R_matrix_md_r = zeros(n_win_bins,1)*nan;
SD.R_matrix_sd_r = zeros(n_win_bins,1)*nan;
SD.R_matrix_skew_r = zeros(n_win_bins,1)*nan;
% SD.R_matrix_kurtosis_r = zeros(n_win_bins,1)*nan;
SD.R_ratio_abv_below_pt3 = zeros(n_win_bins,1)*nan;

SD.S_matrix_mn_r = zeros(n_win_bins,1)*nan;
SD.S_matrix_md_r = zeros(n_win_bins,1)*nan;
SD.S_matrix_sd_r = zeros(n_win_bins,1)*nan;
SD.S_matrix_skew_r = zeros(n_win_bins,1)*nan;
% SD.S_matrix_kurtosis_r = zeros(n_win_bins,1)*nan;
SD.S_ratio_abv_below_pt8 = zeros(n_win_bins,1)*nan;

% Q = Q(:,var(Q,[],1)>0);

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
    [SD.nEffDim(iWin),nl] = n_effective_dimensions(Q);

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
    if  Rows(Q) > 12
        Q = Q(:,var(Q) > 0);
        %         fprintf('nRows Q %d Cols %d \n',Rows(Q),Cols(Q));
        %     if Rows(Q) > 30 && Rows(Q) > Cols(Q) % XXX this is not here in the old version.  In old version it's just --> Rows(Q) > 12
        SD.nSamplesInCalculation(iWin) = Rows(Q);
        %         if window_size_bins == Rows(A) && USE_NBCLUST % only do this once for full matrices as it is computationally very intense.
        if USE_NBCLUST
            %             tic
            C = NbClust_R(Q);
            if isempty(C)
                disp('NBClust_R failed');
            end
            %             toc
            %             [pc,sc,lat] = pca(Q);
            %              C = NbClust_R(Z_scores(Q')');
            %             C = NbClust_R(Z_scores(Q')');
            % tic
            %             Cpca = NbClust_R(sc(:,1:10));
            %             toc
            SD.State_Transition_Matrix{iWin} = State_transition_probabilities(C); % This could be used to generate a measure of how 'persisitent' states tend to be in aged rats.
            u = unique(C);
            H = hist(C,u);
            SD.k_of_NbClust(iWin) = sum(H>min_cluster_members); % to be considered a member of a cluster, there must be at least n members.
        else
            SD.State_Transition_Matrix{iWin} = [];
            SD.k_of_NbClust(iWin) = nan;
        end

        [~,INFO] = Hierarchial_clustering(Q, SD.nKlusts, method);
        %         [Tw,INFOw] = Hierarchial_clustering(Q, SD.nKlusts, 'ward');
        %         [~,sc] = pca(Z_scores(Q')');
        %                  [~,sc] = pca(Q);
        %                  [Tp,INFOp] = Hierarchial_clustering(sc(:,1:3), SD.nKlusts, 'ward');
        % %                  Cw = NbClust_R(sc(:,1:3)); % this does seem to give us more reliable states.

        %         INFO
        SD.Cophenetic_CC(iWin) = INFO.coph;
        SD.k_from_evalclusters_linkage_sil(iWin) = INFO.k_from_evalclusters_linkage_sil; % Good.
        %         SD.k_from_evalclusters_linkage_stdrdized_sil(iWin) = INFO.k_from_evalclusters_linkage_stdrdized_sil;
        %
        SD.k_nBinsGreater2_linkage(iWin) = INFO.k_nBinsGreater2_linkage;
        SD.k_nBins2InRow_linkage(iWin) = INFO.k_nBins2InRow_linkage;
        SD.chi2_of_k_linkage(iWin) = INFO.chi2_of_k_linkage;
        SD.entropy(iWin,:) = INFO.entropy;
        SD.chi2_of_k(iWin,:) = INFO.chi2_of_k_linkage;
        SD.nBinsGreater2(iWin,:) = INFO.nBinsGreater2;
        %
        SD.k_of_min_chi2(iWin) = INFO.k_of_min_chi2; % This is the most reliabl in simulation.
        SD.k_of_max_nBinsGreater2(iWin) = INFO.k_of_max_nBinsGreater2;
        SD.k_from_cutoff_1_linkage(iWin) = INFO.k_from_cutoff_1_linkage;
    end
    %     plot(SD.nKlusts,SD.nBinsGreater2(iWin,:));
    %     toc
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
fprintf('>')
% plot(mean(sort_matrix( SD.entropy)./repmat(SD.nKlusts,Rows(SD.entropy),1)))
% as the icing on the cake- put them all together for a meta measure of
% network state...
f = fieldnames(SD);
M = zeros(length(SD.kurtosis),length(f))*nan;
GIX = false(length(f),1);
for ii = 1:length(f)
    if ~iscell(SD.(f{ii}))
        if size(SD.(f{ii})) == size(SD.kurtosis)
            M(:,ii) = SD.(f{ii})(:)';
            GIX(ii) = true;
        end
    end
end
M = M(:,GIX);
f = f(GIX);

IX = ~isnan(M(1,:));
M = M(:,IX);
f = f(IX);
IX = ~isnan(sum(M,2));
M = M(IX,:);

SD.Net_state_PC1 = zeros(size(SD.nEffDim))*nan;
SD.Net_state_PC2 = zeros(size(SD.nEffDim))*nan;
PCA.Net_weighings = [];
PCA.latent = [];

scores = nan;

if Rows(M)> 20
    [PCA.Net_weighings, scores, PCA.latent] = pca(M);
end

if length(scores)>1
    SD.Net_state_PC1(IX,:) = scores(:,1);
    SD.Net_state_PC2(IX,:) = scores(:,2);
end

if nargout == 0
    figure
    plot_LFP(standardize_range( M ),.2,[],f)

end