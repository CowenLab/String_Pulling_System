function [STM, IXc] = Clean_STM(STM)
% get rid of non-firing cells, and nan's and
% also normalize to standardize the range.
% I chose not to get rid of time bins in which no cell fired - that could
% screw up the timing of the bins if the user is not careful.
% cowen 2014
IXc = sum(STM) > 0;
STM = STM(:,IXc);
% IXr = sum(STM,2) > 0;
% STM = STM(IXr,:);
STM = standardize_range(STM);
