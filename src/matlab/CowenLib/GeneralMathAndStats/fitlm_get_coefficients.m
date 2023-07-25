function [B, b0, p] = fitlm_get_coefficients(mod, n_cols_in_X, p_thresh)
% function [B, b0] = fitlm_get_coefficients(mod, n_cols_in_X, p_thresh)
%
% Extracts the coefficients for the regression model so that they
% correspond to appropriate columns (the IVs) that were passed into the original X
% variable passed to fitlm (or most similar functions that output a model).
%
% if p_thresh exists, then zero out coefficients that are above a certain p
% thresh.
%
% Usage for prediction in regression...
% For a model with the intercept: 
% Bcomplete = [b0 B];
% X = [ones(length(orig_X),1) orig_X]; % add the ones.
% y_hat = Bcomplete'*X;
%
% I could have output Bcomplete, but then the elements of B would not
% correspond to the cols in X.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    p_thresh = 0;
end

B = zeros(1,n_cols_in_X);
b0 = mod.Coefficients.Estimate(1);
col_ix = zeros(1,length(mod.CoefficientNames)-1);
for ii = 2:length(mod.CoefficientNames)
    col_ix(ii-1) = str2double(mod.CoefficientNames{ii}(2:end));
end
B(col_ix) = mod.Coefficients.Estimate(2:end);
p(col_ix) = mod.Coefficients.pValue(2:end);
if p_thresh > 0
    % zero out the potentially bad predictors for a more compact model
    BIX = mod.Coefficients.pValue(2:end) > p_thresh;
    B(col_ix(BIX)) = 0;
end