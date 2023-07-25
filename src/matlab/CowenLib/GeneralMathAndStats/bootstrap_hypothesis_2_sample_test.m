function p = bootstrap_hypothesis_2_sample_test(X,Y,nboot)
% X and Y are the 2 separate vectors of the 2 groups. (so n_samples_1 =
% length(D), n_samples_2 = length(G);
%
% Cowen 2016
if nargin < 3
    nboot = 5000;
end

vv = [X;Y];
n1 = length(X);
n2 = length(Y);
actual_diff = nanmean(X)-nanmean(Y);

% perhform the sub-sampling
m = zeros(nboot,2);
for iBoot = 1:nboot
    m(iBoot,1) = nanmean(randsample(vv,n1,true));
    m(iBoot,2) = nanmean(randsample(vv,n2,true));
end
v = m(:,2)-m(:,1);
[lowup] = prctile(v,[2.5 97.5]);

vs = sort(v);
ix = find(vs >= actual_diff,1,'first');
p = ix/length(vs);
if p > 0.5
    p = 1-p;
end

if nargout == 0
    clf
    subplot(1,3,1)
    histogram(m(:,1),20,'Normalization','probability')
    ylabel('p')
    title('Boot Mean 1')
    subplot(1,3,2)
    histogram(m(:,2),20,'Normalization','probability')
    title('Boot Mean 2')
    subplot(1,3,3)
    histogram(v,20,'Normalization','probability')
    ax = axis;
    hold on
    plot([lowup(1) lowup(1)],ax(3:4),'r:','LineWidth',3)
    plot([lowup(2) lowup(2)],ax(3:4),'r:','LineWidth',3)
    plot([actual_diff actual_diff],ax(3:4),'b','LineWidth',5)
    title(sprintf('2 tailed alpha = 0.05, p = %0.6f',p))
 
    
end