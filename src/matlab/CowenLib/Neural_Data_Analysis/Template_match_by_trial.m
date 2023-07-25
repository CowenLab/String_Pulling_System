function O = Template_match_by_trial(xpos_ctrs,TR,TRFLDS_occnorm,template_trial,nlags)

buf = floor((length(xpos_ctrs) - nlags*2 - 1)/2);

template_trial = intersect(unique(TR),template_trial);
tmp = [];
for iTr = 1:length(template_trial)
    tmp(:,:,iTr) = TRFLDS_occnorm(template_trial(iTr) == TR,:);
end
TP1 = nanmean(tmp,3);

midix = round(length(xpos_ctrs)/2);
ctr_ix = (midix-buf):(midix+buf);
TP = TP1(ctr_ix,:);

lags_ix = -nlags:nlags;
uTr = unique(TR);
r = nan(length(uTr),length(lags_ix));
for iTrl = 1:length(uTr)
    TGT = TRFLDS_occnorm(TR == uTr(iTrl),:);
    %     X(TR==iTrl)
    for iLag = 1:length(lags_ix)
        lg = lags_ix(iLag);
        tg = TGT(ctr_ix + lg,:);
        r(iTrl,iLag) = corrcoef_cowen([TP(:), tg(:)]);
    end
end

[~,ix]= max(r,[],2);
maxlag_ix = lags_ix(ix);
% lags = lags_ix * bin_size_pos;
% maxlag = maxlag_ix * bin_size_pos;

if nargout == 0
    
    imagesc(lags_ix,[],r)
    hold on
    plot(maxlag_ix,1:Rows(r),'k-','LineWidth',3)
    plot(maxlag_ix,1:Rows(r),'w*-')
    
    xlabel('lag INDEX')
    ylabel('trial')
    plot_vert_line_at_zero
    pubify_figure_axis
    colorbar
    
end