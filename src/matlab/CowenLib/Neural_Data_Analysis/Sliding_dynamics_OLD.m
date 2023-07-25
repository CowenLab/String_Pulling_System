function [SD,PCA,SDall,PCAall]= Sliding_dynamics(A, window_size_bins, pop_size_thresh, skip_size, USE_NBCLUST)
% function [SD,PCA,SDall,PCAall]= Sliding_dynamics(A, window_size_bins, pop_size_thresh, skip_size)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% nEffDim - from L Abbott - a measure of the compression or the number of
% effective dimensions that the STM matrix can be compressed.
% sparsity_level = degree of sparsity. Tie bigger the number, the less
% sparse (more dense).
%
% see cluster_demo_cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2015
%
if nargin < 2
    % Don't slide - just computer dynamics for the entire passed in
    % dataset.
    window_size_bins = Rows(A);
end
if nargin < 3
    pop_size_thresh = 2; % need >= 2 events for the population to be considered real.
end
if nargout > 2
    % The user also wants a master dynamics measure - of the entire period.
    [SDall,PCAall]= Sliding_dynamics(A, Rows(A), pop_size_thresh, Rows(A));
%     figure
%     imagesc(SDall.State_Transition_Matrix{1});axis xy
%     title(pwd)
end

if nargin < 5
    USE_NBCLUST = false;
end

SD.aborted_analysis = false;
% Clean A - get rid of unchanging columns or nan's in the COLUMNS (neurons). We will
% deal with zero sized rows later on.
IX = var(A) == 0 | isnan(sum(A));
A = A(:,~IX);

if Rows(A) < window_size_bins
    disp('Not enough bins for the analysis')
    SD.aborted_analysis = true; PCA = [];
    SD.win_bins = [];
    return
end

SD.nKlusts = [3:1:45];
SD.nCells = Cols(A);

if nargin < 4
    skip_size = round(window_size_bins/3); % default is to slide in 1/3 steps.
end
st =  1:skip_size:(Rows(A)-window_size_bins + 1);
ed =  window_size_bins:skip_size:Rows(A);
SD.win_bins = [st(:) ed(:)];
%
n_win_bins = Rows(SD.win_bins);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the indices for the upper diagonal of the R matrix.
% The upper diagonal of A, B, and C will be converted into
% a vector and compared via partial regression.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% idx = find(triu(ones(cols,cols))==0); % Must be 0, else you get the diagonal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now get rid of the indices of the correlations from
% the same tetrodes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% idx = setdiff(idx, on_same_tet_idx(:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main loop - kitchen sink - all interesting network state dyanmics rolled
% into one....
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SD.nSamplesInCalculation = zeros(n_win_bins,1)*nan;

SD.nEffDim = zeros(n_win_bins,1)*nan;
SD.Rolls_Treves = zeros(n_win_bins,1)*nan;
SD.prop_in_first_3comp = zeros(n_win_bins,1)*nan;
SD.kurtosis = zeros(n_win_bins,1)*nan;
SD.prop_active = zeros(n_win_bins,1)*nan;
SD.CV = zeros(n_win_bins,1)*nan;
SD.mean_spikes_per_bin = zeros(n_win_bins,1)*nan;

SD.k_of_min_chi2 = zeros(n_win_bins,1)*nan;
SD.k_of_NbClust = zeros(n_win_bins,1)*nan; % ths can take a long time to compoute. 
% SD.k_of_max_scaled_entropy = zeros(n_win_bins,1)*nan; % not a good measure.
SD.k_of_max_nBinsGreater2 = zeros(n_win_bins,1)*nan;
% SD.k_of_max_CV_Hist_of_k = zeros(n_win_bins,1)*nan; % not a good measure.
SD.k_nBinsGreater2_linkage = zeros(n_win_bins,1)*nan;
SD.k_nBins2InRow_linkage = zeros(n_win_bins,1)*nan;

SD.chi2_of_k_linkage = zeros(n_win_bins,1)*nan;

SD.State_Transition_Matrix = cell(n_win_bins,1);

SD.entropy = zeros(n_win_bins,length(SD.nKlusts))*nan;
SD.scaled_entropy = zeros(n_win_bins,length(SD.nKlusts))*nan;
SD.CV_Hist_of_k = zeros(n_win_bins,length(SD.nKlusts))*nan;
SD.k_nBinsGreater2 = zeros(n_win_bins,length(SD.nKlusts))*nan;
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


tr = triu(ones(Cols(A)),1);
TRIX = tr==1;
tr = triu(ones(window_size_bins),1);
TRIX_Time = tr==1;

% This is inefficient - probaby should skip bins. Probably should also
% restrict to cells with FR > 0.01 and < 3 to get rid of INs.
for iWin = 1:n_win_bins
    Q = A(SD.win_bins(iWin,1):SD.win_bins(iWin,2),:);
    % Ignore population states that have less than a certain threshold of
    % events.
    %     IX = sum(Q>0,2) > pop_size_thresh;
    %     Q = Q(IX,:);
    [tmp,nl] = n_effective_dimensions(Q);
    SD.nEffDim(iWin) = nanmean(tmp);
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
    Qa = Q(sum(Q>0,2)>pop_size_thresh,:); % get rid of zero rows.
    Qa = Qa(:,var(Qa,[],1)>0); % get rid of non-varying columns
    if Rows(Qa) > 12 && Rows(Qa) > Cols(Qa)
        SD.nSamplesInCalculation(iWin) = Rows(Qa);
        if window_size_bins == Rows(A) && USE_NBCLUST % only do this once for full matrices as it is computationally very intense.
            %             tic
            C = NbClust_R(Qa);
            %             toc
            %             [pc,sc,lat] = pca(Qa);
            %              C = NbClust_R(Z_scores(Qa')');
            %             C = NbClust_R(Z_scores(Qa')');
            % tic
            %             Cpca = NbClust_R(sc(:,1:10));
            %             toc
            SD.State_Transition_Matrix{iWin} = State_transition_probabilities(C); % This could be used to generate a measure of how 'persisitent' states tend to be in aged rats.
            SD.k_of_NbClust(iWin) = length(unique(C));
        else
            SD.State_Transition_Matrix{iWin} = [];
            SD.k_of_NbClust(iWin) = nan;
        end
        [pc,sc,lat] = pca(Z_scores(Qa')');
        Y = pdist(Qa,'correlation'); % seuclidean cos %NOTE - I had very interesting results when i clustered OVER Neuron/TIME!!!! The other direction What would this mean.
        Ypca = pdist(sc(:,1:3),'correlation'); % seuclidean cos %NOTE - I had very interesting results when i clustered OVER Neuron/TIME!!!! The other direction What would this mean.
        %     Y = pdist(Qa','euclidean'); % seuclidean
        %         Z = linkage(Qa,'single','correlation'); % note, a default in the literature is ward distance (also default in NbClust in R.
        Z = linkage(Y,'single'); % note, a default in the literature is ward distance (also default in NbClust in R.
        Zward = linkage(Y,'ward'); % note, a default in the literature is ward distance (also default in NbClust in R.
        Zpca = linkage(Ypca,'single'); % note, a default in the literature is ward distance (also default in NbClust in R.
        % May give very different results.
        SD.Cophenetic_CC(iWin) = cophenet(Z,Y); % A measure of the quality of clustering. Higher the better. 
        %         T = cluster(Z,'cutoff',1); % this is the cutoff - but it is so arbiraryr
        T = cluster(Z,'maxclust',max(SD.nKlusts)); % this is the cutoff - but it is so arbiraryr
        Tpca = cluster(Zpca,'maxclust',max(SD.nKlusts)); % this is the cutoff - but it is so arbiraryr
        Tward = cluster(Zward,'maxclust',max(SD.nKlusts)); % this is the cutoff - but it is so arbiraryr
        IXmx = T == mode(T);
        H = hist(T,unique(T)); % Seems like too many clusters generated for large matrices.
        Hp = 100*(H/sum(H));
        SD.k_nBinsGreater2_linkage(iWin) = sum(Hp>0.5); % you need .5% of samples to be considered a cluster.
        hh = zeros(max(H),1);
        for ii = 1:max(H)
            hh(ii) = sum(H>ii);
        end
        % Find 2 in a row in which there was no change in the cluster
        % count.
        d = diff(hh);
        ix = find(d ==0,1,'first')+1;
        if ~isempty(ix)
            SD.k_nBins2InRow_linkage(iWin) = hh(ix);
        else
            SD.k_nBins2InRow_linkage(iWin) = nan;
        end
%         T = cluster(Z,'maxclust',SD.nKlusts); % It is possible to do this
%         all at once, not a huge time savings so no real reason.
        
        expected = ones(size(H))*mean(H);
        SD.chi2_of_k_linkage(iWin) = sum((H-expected).^2./expected); % Chi square formula. This is not a measure of the number of clusters. In fact, I think the goal would be to have a low Chi square - it would indicate that there are more clusters - more evenly spread out.
        %         max_Clust = min([round(Rows(Qa))/2 SD.nKlusts]);
        %     tic
        for iK = 1:length(SD.nKlusts)
            nK = SD.nKlusts(iK);

            if nK < Rows(Qa)/2;
                T = cluster(Z,'maxclust',nK);
                %             c = inconsistent(Z);
                H = hist(T,1:nK);
                Hp = H/sum(H);
                expected = ones(size(H))*sum(H)/nK;
                % Compute measures of the number of clusters observed.
                SD.chi2_of_k(iWin,iK) = sum((H-expected).^2./expected); % Chi square formula. This is not a measure of the number of clusters. In fact, I think the goal would be to have a low Chi square - it would indicate that there are more clusters - more evenly spread out.
                %             SD.CV_Hist_of_k(iWin,iK) = std(Hp)/mean(Hp); % A measure of variance of the distribution. Similar to CHi square. Sensitive to outliers
                SD.entropy(iWin,iK)= -sum(Hp.*log2(eps+Hp)); % forumula for entropy.
                %             SD.scaled_entropy(iWin,iK)=  SD.entropy(iWin,iK)/SD.nKlusts(iK);
                SD.k_nBinsGreater2(iWin,iK) = sum(H>2);
            end
        end
        %
        
        [~,ix] = nanmin(SD.chi2_of_k(iWin,:));
        SD.k_of_min_chi2(iWin) = SD.nKlusts(ix); % This is the most reliabl in simulation.
        %         [~,ix] = max(SD.scaled_entropy(iWin,:));
        %         SD.k_of_max_scaled_entropy(iWin) = SD.nKlusts(ix);
        [~,ix] = nanmax(SD.k_nBinsGreater2(iWin,:));
        SD.k_of_max_nBinsGreater2(iWin) = SD.nKlusts(ix);
        %         [~,ix] = max(SD.CV_Hist_of_k(iWin,:));
        %         SD.k_of_max_CV_Hist_of_k(iWin) = SD.nKlusts(ix);
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
    SMv = SM(TRIX_Time);
    SMv = SMv(~isnan(SMv));
    
    SD.S_matrix_mn_r(iWin) = nanmean(SMv);
    SD.S_matrix_md_r(iWin) = nanmedian(SMv);
    SD.S_matrix_sd_r(iWin) = nanstd(SMv);
    SD.S_matrix_skew_r(iWin) = skewness(SMv);
    %    SD.S_matrix_kurtosis_r(iWin) = kurtosis(SMv);
    SD.S_ratio_abv_below_pt8(iWin) = sum(SMv > 0.8)/(length(TRIX_Time)+ eps);
    
end
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