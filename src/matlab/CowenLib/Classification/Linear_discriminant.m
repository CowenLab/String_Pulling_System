function [LD, Linear_discriminant_wt] = Linear_discriminant(data,group)
%function [LD, Linear_discriminant_wt] = Linear_discriminant(data,group)
% Linear discriminant
% This function transforms the data in data into the coordinate system
% determined by fishers linear discriminant. The transformation matrix is
% returned in xform.
% data is n samples by n dimension.
% group is a vector indicating group membership of each sample.
% the LD is always one dimensional.
%
% Cowen

GIX = ~isnan(sum(data,2));
group_ids = unique(group(GIX));
nGroups = length(group_ids); % Can only be 2
if nGroups ~= 2
    error('Must only have only 2 groups')
end
group1_IX = group == group_ids(1);
group2_IX = group == group_ids(2);

sw		   = cov(data(group1_IX,:)) + cov(data(group2_IX,:));
% Linear_discriminant_wt = inv(sw)*(mean(data(group1_idx,:))-mean(data(group2_idx,:)))';
warning off
Linear_discriminant_wt = sw\(mean(data(group1_IX,:))-mean(data(group2_IX,:)))';
warning on
Linear_discriminant_wt = Linear_discriminant_wt';

LD = zeros(Rows(data),1);
tmp         = Linear_discriminant_wt*data(GIX,:)';
LD(GIX) = tmp(:);
    