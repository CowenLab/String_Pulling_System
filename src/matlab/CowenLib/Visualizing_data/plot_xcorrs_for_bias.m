function F = plot_xcorrs_for_bias(CC_by_epoch, xdim, epoch_names, plot_type)
% Visualize any preserved asymmetry between epoch crosscorrs.
%
% INPUT: CC_by_epoch - cell array of cross-correlations
%        xdim - the xdimension
%        epoch_names - cell array of text names.
%        plot_type:
% 'averaged'
%   simply averages across the epochs and returns the mean crosscorr
%   contrasted with a crosscorr genereated by randomly reversing a random
%   half of the crosscorrs.
%
% 'folded'
%   Create a plot of the flipped xcorrs. This assumes that the crosscorrs
%   have been presorted an reversed according to one epoch and that this rule
%   had been applied to the other epochs. This program then folds all of the
%   crosscorrs over, computes the difference and normalizes by some estimate
%   of the variation of the xcorr.
%
% OUTPUT: plot of the flipped crosscorrs.
%
% cowen
nepochs = length(epoch_names);
nbins = cols(CC_by_epoch{1});
nperms = 40;
lbins = 1:floor(nbins/2);
rbins = (ceil(nbins/2)+1):nbins;

clf
a = zeros(nepochs,4);
for iEp = 1:nepochs
    subplot(ceil(nepochs)/2,2,iEp)
    switch plot_type
        case 'averaged'
            % First normalize each CC by an estimate of error.
            %  
            %             n_mn = mean(CC_by_epoch{iEp}(:,[1:20 (end-20):end])');
            %             n_sd = std(CC_by_epoch{iEp}(:,[1:20 (end-20):end])')+eps;
            %             CC_by_epoch{iEp} = CC_by_epoch{iEp} - repmat(n_mn(:),1,cols(CC_by_epoch{iEp}));
            %             CC_by_epoch{iEp} = CC_by_epoch{iEp} ./ repmat(n_sd(:),1,cols(CC_by_epoch{iEp}));
            
            plot(xdim, mean(CC_by_epoch{iEp}),'k','LineWidth',2);
            hold on
            plot(xdim, mean(CC_by_epoch{iEp})+Sem(CC_by_epoch{iEp}),'k','LineWidth',2);
            plot(xdim, mean(CC_by_epoch{iEp})-Sem(CC_by_epoch{iEp}),'k','LineWidth',2);
            [mn,se] = random_reverse_half(CC_by_epoch{iEp},20);
            plot(xdim, mn,'g','LineWidth',2);
            plot(xdim, mn+se,'g','LineWidth',1);
            plot(xdim, mn-se,'g','LineWidth',1);
            grid on
        case 'folded'
            % fold
            %            Folded = CC_by_epoch{iEp}(:,lbins) -
            %            CC_by_epoch{iEp}(:,rbins(end:-1:1));
            % subtract the mean.
%            Folded = CC_by_epoch{iEp}(:,lbins) - repmat(mean(CC_by_epoch{iEp}(:,rbins)')',1,length(rbins));
            % fold
            Folded = CC_by_epoch{iEp}(:,lbins) - CC_by_epoch{iEp}(:,rbins(end:-1:1)); 
            mn = mean(Folded);
            se = Sem(Folded);
            plot(xdim(lbins), mn,'k','LineWidth',2);
            hold on
            plot(xdim(lbins), mn + se,'k','LineWidth',1);
            plot(xdim(lbins), mn - se,'k','LineWidth',1);
            plot(xdim(lbins),zeros(size(xdim(lbins))),'r','LineWidth',2)
    end
    title(epoch_names{iEp})
    if iEp == 1
        xlabel('msec')
    end
    axis tight
    a(iEp,:) = axis;
end
% change the axes so that they are at the same scale.
best_a = [min(a(:,1)) max(a(:,2)) min(a(:,3)) max(a(:,4))];
for iEp = 1:nepochs
    subplot(ceil(nepochs)/2,2,iEp)
    axis(best_a);
end
function [mn,se]  = random_reverse_half(CC,n_perm_samples)
% Create data for permutation testing the asymmetry in CC.
%   Create data witht he left and right randomly permuted.
% nreps = ceil(n_perm_samples/rows(CC));
% P = repmat(CC,nreps,1);
% r = randperm(rows(P));
% reverse_ix = r(1:round(length(r)/2));
% P(reverse_ix,:) = P(reverse_ix,end:-1:1); 

% The following is the proper way - but slower way - to do permutation
% testing.
[rws,cls] = size(CC);
mn = zeros(n_perm_samples,cls);
for iS = 1:n_perm_samples
    pCC = CC;
    r = randperm(rws);
    reverse_ix = r(1:round(length(r)/2));
    pCC(reverse_ix,:) = pCC(reverse_ix,end:-1:1);
    mn(iS,:) = mean(pCC);
    se(iS,:) = Sem(pCC);
end
% hist(mn,20)
mn = mean(mn);
se = mean(se);
return

