function [all_q all_lr] = cluster_quality(D,g)
% returns measures of cluster quality for each cluster in g. l ratio for each group in g.
%  first column is group id, second is the lratio of that element.
%
%  Quality measures:
%     q - modification of fellous
%    lr - l-ratio
%
%  INPUT: Data - nsamples X n features
%         g - group.
%  OUTPUT: 2 col where 1st is group, second is value.
ug = unique(g);
all_q = zeros(length(ug),2);
all_lr = zeros(length(ug),2);
for iG = 1:length(ug)
    ix_in = find(g == ug(iG));
    ix_out = find(g ~= ug(iG));
    %
    n_in = length(ix_in);
    n_out = length(ix_out);
    %
    within_m = nanmean(D(ix_in,:));
    without_m = nanmean(D(ix_out,:));
    m_in = mean([D(ix_in) - within_m].^2);
    if n_out > 0
        m_out = mean([D(ix_out) - within_m].^2);
    else
        m_out = m_in;
    end
   % q = mean([D(ix_out) - within_m].^2)./mean([D(ix_in) - within_m].^2); % yes, they both are within - see Fellous Sejnowski.
    q = (m_out-m_in)./(m_out+m_in); % yes, they both are within - see Fellous Sejnowski.
    %
    %
    %if isempty(ix_out)
    %    ix_out = ix_in;
    %end
    lr = sum(1-chi2cdf([D(ix_out) - within_m].^2, n_in+n_out));
    all_q(iG,:) = [ug(iG) q];
    all_lr(iG,:) = [ug(iG) lr];
end
