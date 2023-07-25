function [r,lags,maxlag,OUT] = Place_Field_Expansion_Population_Analysis(SPrun, ...
    POS_Lin, pos_bin_edges, smooth_win_size, TrialStartEnd, template_trial, nlags, method)
% Assumes linearized position.
% 1) Bin spikes by time by trial so that you get spike counts for each
% spatial bin.
% 2) Do the same with position - to get occupancy for each location.
% 3) Occupancy normalize each spike count.
%
% 1) Choose one trial (the template trial) as the template.
% 2) Perform PCA on the entire dataset to reduce dimensionality to 80% of
% the data.
% 3) Calculate the correlation coefficitnt between the template matrix for
% the template trial and the zero spatial lag correlation with all of the
% other trials. You will get an R value for each trial for each lag. This
% will become a trial (row) by lag (col) matrix of correlation
% coefficients = TLC (trial, lag, Correlation).
% 4) determine the lag for each trial as the
% Cowen 2019
if nargin == 0
    pth = fileparts(which('Place_Field_Expansion_Population_Analysis'));
    load(fullfile(pth,'Place_Field_Expansion.mat'))
end
COMBINE_ADJACENT = true;
% method = 'raw_spiking';
bin_size_pos = mean(diff(pos_bin_edges));
xpos_ctrs = pos_bin_edges(1:end-1) + bin_size_pos/2;
hn = hanning(smooth_win_size);
% Determine occupancy on each trial...
Occ = nan(Rows(TrialStartEnd),length(pos_bin_edges)-1);
for iTrial = 1:Rows(TrialStartEnd)
    pl = Restrict(POS_Lin,TrialStartEnd(iTrial,:));
    Occ(iTrial,:) = histcounts(pl(:,2),pos_bin_edges);
end
% figure
% plot(xpos_ctrs,Occ')
% convert to seconds
% Occ = Occ./GP.Tracking_Sample_Rate_Hz;
% OUT.Occ_total(iEpoch,:) = nanmean(Occ);
% Determine the location for each spike...
for iCell = 1:length(SPrun)
    if ~isempty(SPrun{iCell})
        LOC = interp1(POS_Lin(:,1),POS_Lin(:,2),SPrun{iCell}(:,1)*100,'linear');
        SPrun{iCell}(:,2) = LOC;
    end
end
% nlags = 10;
buf = floor((length(xpos_ctrs) - nlags*2 - 1)/2);
TRFLDS_occnorm = [];
for iCell = 1:length(SPrun)
    F = nan(Rows(TrialStartEnd),length(xpos_ctrs));
    for iTrial = 1:Rows(TrialStartEnd)
        SPrunR = Restrict(SPrun{iCell}, TrialStartEnd(iTrial,:)/100);
        if ~isempty(SPrunR)
            F(iTrial,:) = histcounts(SPrunR(:,2),pos_bin_edges);
        else
            F(iTrial,:) = 0;
        end
    end
    %     TRFLDS(1:Rows(F),:,iCell) = F;
    tmp = F./Occ;
    tmp(isnan(tmp)) = 0;
    TRFLDS_occnorm(1:Rows(F),:,iCell) = convn(tmp',hn,'same')';
end
if COMBINE_ADJACENT
    for iTrl = 1:(size(TRFLDS_occnorm,1)-1)
        TRFLDS_occnorm(iTrl,:,:) = nanmean(TRFLDS_occnorm(iTrl:(iTrl+1),:,:),1);
    end
end
FA = [];
TR = [];
X = [];
for iTrl = 1:size(TRFLDS_occnorm,1)
    FA = [FA;squeeze(TRFLDS_occnorm(iTrl,:,:))];
    TR = [TR;ones(size(TRFLDS_occnorm,2),1)*iTrl];
    X = [X;xpos_ctrs(:)];
end
% GIX = ~isnan(sum(FA,2));
% FA(GIX,:) = convn(FA(GIX,:),hn,'same');
FA(isnan(sum(FA,2)),:) = 0;
FA(isinf(sum(FA,2)),:) = 0;
switch method
    case 'pca'
        [~,SC,lat] = pca(FA);
        lat = lat/sum(lat);
        SC = SC(:,cumsum(lat) <= .85);
    case 'raw_spiking'
        SC = FA;
end
% The template.
template_trial = intersect(unique(TR),template_trial);
tmp = [];
for iTr = 1:length(template_trial)
    tmp(:,:,iTr) = SC(template_trial(iTr) == TR,:);
end
TP1 = nanmean(tmp,3);


midix = round(length(xpos_ctrs)/2);
ctr_ix = (midix-buf):(midix+buf);
TP = TP1(ctr_ix,:);

lags_ix = -nlags:nlags;
r = nan(size(TRFLDS_occnorm,1),length(lags_ix));
for iTrl = 1:size(TRFLDS_occnorm,1)
    TGT = SC(TR == iTrl,:);
%     X(TR==iTrl)
    for iLag = 1:length(lags_ix)
        lg = lags_ix(iLag);
        tg = TGT(ctr_ix + lg,:);
        r(iTrl,iLag) = corrcoef_cowen([TP(:),tg(:)]);
    end
end

[~,ix]= max(r,[],2);
maxlag_ix = lags_ix(ix);
lags = lags_ix * bin_size_pos;
maxlag = maxlag_ix * bin_size_pos;

if nargout > 3
    OUT.SC = SC;
    OUT.TR = TR;
    OUT.X = X;
end

if nargout == 0
    
    figure
    imagesc(lags,[],r)
    hold on
    plot(maxlag,1:Rows(r),'w*-')
    
    xlabel('lag')
    ylabel('trial')
    plot_vert_line_at_zero
    pubify_figure_axis
    colorbar
    
end