function [c, pc, p, tbl] = classify_cross_validate(d,g,classify_fun)
%function [c] = classify_cross_validate(d,g,classify_fun)
%
% Cross-Validation Classification - leave one out using matlab classify.
%
% INPUT: nsample by ndimension data
%        g = group
%        (optional) - classify function handle - pass in a classification
%        function - must have the same first 3 input arguments as matlab's classify
%        command. (examples: tree_classify, Bayes_discriminator,
%           classify_svm, nn_marq_classify, bayes_partition_class_wrapper)
%
% OUTPUT: Selected category.
%         percent correct
%         probability this is above chance (chi square)
%         crosstab table (confusion matrix)
%
% NOTE: Classify cannot handle xor. It's a simple linear classifier.
% NOTE: The e value that comes from matlab's classify does not go to chance 
% when you put in random data so I don't trust it - hence it was eliminated.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      cowen(2006)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
if nargin < 3
    classify_fun = @classify; % Default to matlab's linear classifier.
end
pc = nan; p = nan; tbl = zeros(length(unique(g)))*nan; c = g*nan;
%
[st,counts] = grpstats(d,g,{'std' 'numel'});
% Ignore situations when the minimum std is toooo low.
if  ~strcmp('tree_classify',func2str(classify_fun))
    if min(st) < 0.01 | min(counts) < 5  | length(unique(g)) == 1
        warning('Not enough training elements or variance in the data. Returining nans')
        %return
    end
end
nS=size(d,1);
c = zeros(nS,1)*nan;
for ii = 1:nS
    trix = setdiff(1:nS,ii);
    c(ii) = classify_fun(d(ii,:),d(trix,:),g(trix));
end

% Compute some summary stats.
if nargout > 1
    ix = find(isnan(c));
    if length(ix) > 3
        disp('WARNING: not positive definite. STATS COULD BE SCREWED UP.')
    else
        pc = mean(c==g);
        [tbl,chi,p] = crosstab(g,c);
    end
end

