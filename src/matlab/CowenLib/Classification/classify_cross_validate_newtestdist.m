function [c, pc, p, tbl] = classify_cross_validate_newtestdist(d,g,d2,classify_fun)
%function [c] = classify_cross_validate_newtestdist(d,g,d2,classify_fun)
%
% Cross-Validation Classification - leave one out using matlab classify.
% - ALLOWS USER TO PASS IN A NOVEL DISTRIBUTION OF TEST DATA THAT WAS NOT
% USED IN THE TRAINING. IT MUST BE THE SAME SIZE AS D.
% INPUT: nsample by ndimension data
%        g = group
%        (optional) - classify function handle - pass in a classification
%        function - must have the same first 3 input arguments as matlab's classify
%        command. (examples: tree_classify, Bayes_discriminator,
%            classify_svm, nn_marq_classify, bayes_partition_class_wrapper)
%
% OUTPUT: Selected category.
%
% - Use confusion_matrix(g,c) to compute the confusion matrix.
% - Use mean(g==c) to get the overall percent correct.
%
% NOTE: Classify cannot handle xor. It's a simple linear classifier.
% NOTE: The e value that comes from matlab's classify does not go to chance 
% when you put in random data so I don't trust it - hence it was eliminated.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      cowen(2006)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4 | isempty(classify_fun)
    classify_fun = @classify; % May work better for some binned spike data. Also doesn't care about
    %positive definite problem.
   % classify_fun = @classify; % Default to matlab's linear classifier.
   % classify_fun = @nn_marq_classify
end
if isempty(d2) 
    d2 = d; % revert to standard cross validate if different test data not provided;
end
pc = nan; p = nan; tbl = zeros(length(unique(g)))*nan; c = g*nan;
[st,counts] = grpstats(d,g,{'std' 'numel'});
% Ignore situations when the minimum std is toooo low.
if min(st) < 0.01 | min(counts) < 5 | length(unique(g)) == 1
    warning('Not enough training elements or variance in the data. Returining nans')
    return
end

    
% compress the data if there are too many dimensions for classify to work.
% - Hard coded so not optimal. There are much better ways to do this.
%h = hist(g,unique(g));
%mindims = round(min(h)/3); % Rule of thumb.
% Are there zero std cols?
mindims = min([Cols(d) 9]);
% A little heuristic -- if cols < 4 then just use one PC.
if Cols(d) < 4
    mindims = 1;
end

if Cols(d) > 2 & ~strcmp('tree_classify',func2str(classify_fun))  & ~strcmp('classify_svm',func2str(classify_fun))
    %    [PC,dred] = princomp(d,'econ');
    % There must be a better way, but this is all I've got for now. I
    % wonder if fastica would do the trick?
    % subtract mean - that seems optional.
    if 0
        dd  = d  - repmat(mean(d), Rows(d), 1);
        d22 = d2 - repmat(mean(d2),Rows(d2),1);
    else
        dd  = d;
        d22 = d2;
    end
    %dd = d;
    %d22 = d2;
    if 0
        % Use ICA to do the same and then remove columns that are not of sufficient variance..
        % add this toolbox: U:\Cowen\Src\matlab\Toolboxes\FastICA_25
        % EXPERIMENTAL!! AT THE MOMENT IT DOES NOT WORK,.
        [A, W]=fastica(dd', 'verbose', 'off', 'displayMode', 'off','displayInterval',1000);
        % convert back to original
        dd  = W*dd';
        d22 = W*d22';
        dd  = dd';
        d22 = d22';
        %dd  = dd - repmat(mean(dd),Rows(dd),1);
        %d22 = d22 - repmat(mean(d22),Rows(d22),1);
        %    icasig = W * mixedsig + (W * mixedmean) * ones(1, NumOfSampl);
    end
    % Use PC to compress and remove possibility for positive definite
    % problem.
    dd = nan_to_val(dd);
    [U,sigma,coeff] = svd(dd,'econ'); % put in 1/sqrt(n-1) later
    sigma = diag(sigma);
    score = U .* repmat(sigma',Rows(d),1); % == x0*coeff
    score2 = d22*coeff;
    %
    ix = 1:mindims;
    d  = (score(:,ix));
    d2 = (score2(:,ix));
    % Use Princomp to compress.
    % princomp automatically subtracts the mean so you need to do this with
    % d2 as well.
    % One way to test for positive definiteness---
    % chol(p) - will return an error if it is not pd.
    %ix = find( std(dred) > eps );
end

nS=size(d,1);

for ii = 1:nS
    trix = setdiff(1:nS,ii);
    try
        c(ii) = classify_fun(d2(ii,:),d(trix,:),g(trix));
    catch
        le = lasterror;
        le.message
    end
end
if nargout > 1
    ix = find(isnan(c));
    if length(ix) > 3
        disp('WARNING: not positive definite. STATS COULD BE SCREWED UP.')
    else
        pc = mean(c==g);
        [tbl,chi,p] = crosstab(g,c);
    end
end
