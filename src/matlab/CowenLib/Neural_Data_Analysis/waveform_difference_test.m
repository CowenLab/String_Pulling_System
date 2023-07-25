function [p,manova_stats] = waveform_difference_test(t, wv, G, do_ld_test, plot_it)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine if 2 clusters are significantly different from each other.
%
% INPUT: t - timestamps 1/10 msec.
%        wv - waveform data wv(sample,channels(4),samples(32))
%        G  - a vector indicating the cluster member of each waveform
%             e.g. 1 1 1 1 1 2 2 2 1 1 2 1.
%        do_ld_test (0 or 1) - do a xval linear discriminant test - slow but a very
%         good test - a good check and comparison to the manova.
%        plot_it (0 or 1) - optional - plot the waveforms and the LD distributions.
%
% OUTPUT: 
%       p.manova - pvalue from a manova test on the waveform shape.
%       p.LD_xval - pvalue from the linear discriminant between the 2
%          groups (cross-validation so the model was tested on virgin data)
%
% cowen (2005)
% NOTE: I tried some permutation testing with mahalanobis distance without
% much success (no differnece in clearly different waveforms). I am leaving
% the code in here for future explorations.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4
    do_ld_test = 1; % do the cross-val Lin Disc test - slow but good. Should give similar values to the manova.
end

if nargin < 5
    plot_it = 0;
end

wv = wv(:,:,4:22); % ignore some of the less interesting points.
nChannels = size(wv,2);
nPts = size(wv,3);
u = unique(G);

if length(u) ~=2
    error('only 2 clusters allowed')
end

nSamples = size(wv,1);

for ii = 1:length(u)
    ix{ii} = find(G==u(ii));
    nvals(ii) = length(ix{ii});
end

bad_channels = [];
for iCh = 1:nChannels
    if sum(squeeze(mean(wv(:,iCh,:)))) == 0
        bad_channels = [bad_channels; iCh];
    end
end

disp([ 'Found ' num2str(length(bad_channels)) ' bad channels'])
good_channels = setdiff(1:nChannels,bad_channels);
%new_wv = reshape(wv(:,good_channels,:), nSamples, length(good_channels)*nPts,1);

new_wv = reshape(permute(wv(:,good_channels,:),[1,3,2]), nSamples, length(good_channels)*nPts,1);
%
%d.corr_div_std = corr([mean(new_wv(ix{1},:))./std(new_wv(ix{1},:))]',[mean(new_wv(ix{2},:))./std(new_wv(ix{2},:))]');
%d.corr = corr(mean(new_wv(ix{1},:))',mean(new_wv(ix{2},:))');
[D,p.manova,manova_stats] = manova1(new_wv,G,0.05);
% Sanity check.
Gperm        = G(randperm(length(G)));
[D,p.manova_perm] = manova1(new_wv,Gperm,0.05);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compare these results to the results of comparing spikes WITHIN a
% cluster - by say first to last spike in a burst. This should give a measure of the degree of variation within
% cluster and put any between cluster differences in perspective.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
BURST = burst_info(t*100);
G1 = BURST.first_in_burst_grp > 0;
G2 = BURST.last_in_burst_grp > 0;
G2 = 2*G2;
first_last_burst_G = G1 + G2;
all_ix = find(first_last_burst_G>0);
[D,p.manova_burst] = manova1(new_wv(all_ix,:),first_last_burst_G(all_ix),0.05);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% After testing, I found that the raw LD without cross-validation is
% DANGEROUS - hugely significant values when there is nothing significant.
% Use the Jackknifed/Cross validaiton approach instead. The manova1
% approach also appears to be extremely reliable and accurate.
%
%[LD,WT] = Linear_discriminant(new_wv,G);
%[H,p.LD] = ttest2(LD(ix{1}),LD(ix{2}));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
LD_xval = zeros(nSamples,1)*nan;
if do_ld_test
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % This is leave one out cross validation or jackknifing in the
    % statistics literature. You can't use the same data to build and test
    % your model. A pity it takes so long.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for ii =1:nSamples
        subsample = setdiff(1:nSamples,ii);
        [tmpLD,WT] = Linear_discriminant(new_wv(subsample,:),G(subsample),1);
        LD_xval(ii) = WT*new_wv(ii,:)';
        if mod(ii,20) == 0
            fprintf('>')
        end
    end
    fprintf('\n')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Perform the test on the cross validated data.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [H,p.LD_xval] = ttest2(LD_xval(ix{1}),LD_xval(ix{2}));
else 
    p.LD_xval = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tried and failed to get mahalanobis/permutation test to work. Save for
% later.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0
    perm_d_vals = zeros(nperms,1);
    nperms = 500;
    
    % Mahal - the matlab version - doesn't appear to work at all.
    d.mahala         = mahala(new_wv(ix{1},:), new_wv(ix{2}, :))
    %d.mahal          = mean(mahal(new_wv(ix{1},:), new_wv(ix{2}, :)));
    
    %
    combo_ix = zeros(1,min(nvals)*2);
    min_nvals = min(nvals);
    for ii = 1:nperms
        perm_ix1 = randperm(nvals(1));
        perm_ix2 = randperm(nvals(2));
        if nvals(1) > nvals(2)
            combo_ix(1,:) = [ix{1}(perm_ix1(1:nvals(2))) ix{2}(perm_ix2(1:nvals(2)))];
        else
            combo_ix(1,:) = [ix{1}(perm_ix1(1:nvals(1))) ix{2}(perm_ix2(1:nvals(1)))];
        end
        % half = floor(length(combo_ix)/2);
        perm_d_vals(ii) = mahala(new_wv(combo_ix(1:min_nvals),:),new_wv(combo_ix((min_nvals+1):end),:));
        %    perm_d_vals(ii) = mean(mahal(new_wv(combo_ix(1:min_nvals),:),new_wv(combo_ix((min_nvals+1):end),:)));
        %    perm_d_vals(ii) = corr(mean(new_wv(combo_ix(1:min_nvals),:))',mean(new_wv(combo_ix((min_nvals+1):end),:))');
        if mod(ii,20) ==0
            fprintf('>')
        end
        % perm_d_vals(ii) = corr(mean(new_wv(combo_ix(1:min_nvals),:))',mean(new_wv(combo_ix((min_nvals+1):end),:))');
    end
    %perm_d_vals = permutation_distribution(nperms,@corr,new_wv(ix{1},:),new_wv(ix{2},:));
    
    upper_pval = length(find(perm_d_vals >= d.mahala))/length(perm_d_vals);
    lower_pval = length(find(perm_d_vals < d.mahala))/length(perm_d_vals);
    p.perm = min([upper_pval lower_pval]) * 2; % I multply by 2 to get the 2 tailed probability as there is no a-priori prediction.
end



if plot_it
    %    hist(perm_d_vals,30)
    %    hold on
    %    plot(d.mahala,0,'r^')
    %    title([' perm p ' num2str(p.perm) ' manova p ' num2str(p.manova)  ' LD p ' num2str(p.LD_xval) ] )
    %    subplot(3,1,2)
    subplot(3,1,1)
    h = errorbar(1:size(new_wv,2), mean(new_wv(ix{1},:)), Sem(new_wv(ix{1},:)));
    set(h,'Color','b')
    hold on
    h = errorbar(1:size(new_wv,2), mean(new_wv(ix{2},:)), Sem(new_wv(ix{2},:)));
    set(h,'Color','r')
    title([' manova p ' num2str(p.manova)  ' LD p ' num2str(p.LD_xval) ] )
    subplot(3,1,2)
    % plot the within cluster comparison. - well first versus second in
    % burst.
    tmpix = find(first_last_burst_G == 1);
    h = errorbar(1:size(new_wv,2), mean(new_wv(tmpix,:)), Sem(new_wv(tmpix,:)));
    set(h,'Color','b')
    hold on
    tmpix = find(first_last_burst_G == 2);
    h = errorbar(1:size(new_wv,2), mean(new_wv(tmpix,:)), Sem(new_wv(tmpix,:)));
    set(h,'Color','r')
    title(['First and last in burst:  manova burst p ' num2str(p.manova_burst) ] )
    subplot(3,1,3)
    [h1,r1] = hist(LD_xval(ix{1}),30); h1 = h1/max(h1);
    [h2,r2] = hist(LD_xval(ix{2}),30); h2 = h2/max(h2);
    plot(r1,h1,r2,h2)
    title('Lin Disc')
end