function [pvals, is_sig, max_ncontig] = PETH_shuffle_sig_test(PTH,nPerm,nContigAbove,pthresh)
% Compare actual mean across trials with shuffled means. Use these
% differences as the sampling distribution and compare actual mean or diff
% with the distribution (as per z score) to determine the pvalue. %

% method = 'permtest_within'; % controls for trial-to-trial variation in
% means as it computes a difference score within each trial and only
% shuffles wihtin a trial.
method = 'permtest'; % Standard perm test, but if you want to control for trial-to-trial variation in firing rates, then you should normalize by trial BEFORE passing in.
if nargin < 2
    nPerm = 200;
    nContigAbove = 1;
    pthresh = 0.05; %
end

nCols = Cols(PTH);

switch method
    case 'permtest'
        % permutation test.
        % simple: for nPerms, shuffle vals WITIN each row. Recompute global
        % mean. The problem with this test is that it will be corrupted by
        % non-stationarities from trial to trial (row to row) as there is no within-trial delta measure.
        % HOWEVER: if you normalize (baseline) the row-to-row means before passing it
        % into this function, then you should be fine.
        MN = nan(nPerm,nCols);
        %         shifts = round(rand(nPerm,Rows(PTH))*(Cols(PTH)-2))+1;
        parfor iP = 1:nPerm
            %  I have done it this way and with circshift and the results are effectively identical.
            PTHtmp = nan(size(PTH));
            for iR = 1:Rows(PTH)
                PTHtmp(iR,:) = PTH(iR,randperm(nCols));
            end
            %             PTHtmp = circshift_matrix(PTH',shifts(iP,:))';
            MN(iP,:) = nanmean(PTHtmp);
        end
        z = (nanmean(PTH)-nanmean(MN(:)))./nanstd(MN(:)); % Deviation from zero.
        
        pvals = 1-normcdf(abs(z));
        pvals = pvals * 2;% Assume one tailed so mult pvals * 2.
        
    case 'permtest_within'
        % Just work with difference scores. WITHIN-TRIAL computation to deal with non-stationarities.
        % This variant accounds for TRIAL - TO TRIAL non-statinarities. An
        % important consideration for PETHS
        MN = nan(nPerm,nCols);
        MN2 = nan(nPerm,nCols); % this is for estimating the SD
        parfor iP = 1:nPerm
            %  I have done it this way and with circshift and the results are effectively identical.
            %  for iR = 1:Rows(PTH)
            %                     PTHtmp(iR,:) = PTH(iR,randperm(nCols));
            %                 end
            shifts = round(rand(1,Rows(PTH))*Cols(PTH));
            PTHtmp = circshift_matrix(PTH',shifts)'; % keeps wi trial stats.
            shifts = round(rand(1,Rows(PTH))*Cols(PTH));
            PTHtmp2 = circshift_matrix(PTH',shifts)'; % keeps wi trial stats.
            
            MN(iP,:) = nanmean(PTH-PTHtmp);
            MN2(iP,:) = nanmean(PTHtmp2 - PTHtmp);
        end
        z = nanmean(MN)./nanstd(MN2); % Deviation from zero.
        % Use density estimate to avoid normality assumption. Not really
        % necessary given the large number of permutations
        % I also tried this empirically and the results are VERY similar to the z score
        % method and probably MUCH more overhead so probably not worth it
        % unless you have strange sampling distributions. An alterniative
        % would be to remove extreme values as well just to increase
        % reliability of measure - or just increase nPerm.
        %         p = nan(1,Cols(MN));
        %         for iC = 1:Cols(MN)
        %             [f,x] = ksdensity(MN(:,iC));
        %             IX = x > 0;
        %             IX2 = x < 0;
        %             p(iC) = min([sum(f(IX)/sum(f)) sum(f(IX2)/sum(f)) ]) * 2; % mult x2 because 2 sided.
        %         end
        
        pvals = 1-normcdf(abs(z));
        pvals = pvals * 2;% Assume one tailed so mult pvals * 2.

        
    case 'permtest_withinjhjkh'
        % this is also called a permutation test.
        % Compute the DIFFERENCE from 2 randomly sampled copies and the
        % mean. Then, look how far the actual mean deviates from the random
        % mean (and divide by shuffled deviation to get z scores and p
        % values).
        MN = nan(nPerm,nCols);
        MNd = nan(nPerm,nCols);
        for iP = 1:nPerm
            %  I have done it this way and with circshift and the results are effectively identical.
            %  for iR = 1:Rows(PTH)
            %                     PTHtmp(iR,:) = PTH(iR,randperm(nCols));
            %                 end
            shifts = round(rand(1,Rows(PTH))*Cols(PTH));
            PTHtmp1 = circshift_matrix(PTH',shifts)'; % keeps wi trial stats.
            shifts = round(rand(1,Rows(PTH))*Cols(PTH));
            PTHtmp2 = circshift_matrix(PTH',shifts)'; % keeps wi trial stats.
            MN(iP,:) = nanmean([PTHtmp1; PTHtmp2]);
            MNd(iP,:) = nanmean(PTHtmp1-PTHtmp2);
        end
        z = (nanmean(PTH) - nanmean(MN))./nanstd(MNd); % Deviation from zero.
        pvals = 1-normcdf(abs(z));
        pvals = pvals * 2;% Assume one tailed so mult pvals * 2.
    case 'repeatsignrankpermtest'
        % This is a much more stringent test. Do a repeated one sample
        % signrank test 200 times with shuffled data. The proportion of
        % false-positives in these. It's a cool test though - use only if
        % you have to be 1000% positive for every case.
        % I think that the p values here need to be ajdusted in some way
        % but I am not sure how.
        %%%%%%%%% True permutatin tests...
        P = nan(nPerm,nCols);
        r = Rows(PTH);
        parfor iP = 1:nPerm
            % in practice virtually no difference between circshift and
            % randperm. Both work.
            %              shifts = round(rand(1,r)*nCols);
            %              P(iP,:) = signrank_matrix(circshift_matrix(PTH',shifts)'-PTH);
            PTHtmp = ones(size(PTH));
            
            for iR = 1:r
                PTHtmp(iR,:) = PTH(iR,randperm(nCols));
            end
            P(iP,:) = signrank_matrix(PTHtmp-PTH);
        end
        % bar(sum(P<0.05)./nPerm)
        pvals = 1-nanmean(P<pthresh); % What portion of these tests are significant? That's what pvals is.
    otherwise
        error('incorrect type')
end

contig = Count_contiguous(pvals < pthresh);
max_ncontig = max(contig);
is_sig = max_ncontig >= nContigAbove;

if nargout ==0
    %%
    clf
    subplot(2,1,1)
    imagesc(PTH)
    title(num2str(max_ncontig))
    
    subplot(2,1,2)
    plot(nanmean(MN))
    hold on
    plot(nanmean(MN) + std(MN)*1.96)
    plot(nanmean(MN) - std(MN)*1.96)
    plot(nanmean(PTH),'k');
    plot(nanmean(PTH) + Sem(PTH),'r');
    plot(nanmean(PTH) - Sem(PTH),'r');
    ix = find(pvals < pthresh);
    plot(ix,nanmean(PTH(:,ix)),'m.')
    ix = find(pvals < pthresh & contig >= nContigAbove );
    plot(ix,nanmean(PTH(:,ix)),'cp')
    axis tight

    plot_horiz_line_at_zero
    %     ix = find(pvals_perm < pthresh);
    %
    %     plot(ix,nanmean(PTH(:,ix)),'go')
end