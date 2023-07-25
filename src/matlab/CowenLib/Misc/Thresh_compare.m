function [n_correct,perc_correct,...
    n_correct_by_col,perc_correct_by_col,act_by_cat] = Thresh_compare(A,Des)
% Compare A to Des. Assume A is an activation
% INPUT
%  A = a matrix of activations where each row is a sample
%  Des = the desired output
%
% OUTPUT
%  n_correct           = the number of samples that were the top response and
%                        were also the desired output.
%  perc_correct        = the percentage correct.
%  n_correct_by_col    = number correct for each column(category).
%  perc_correct_by_col = the percentage correct for each column.
%  perc_correct_by_col = the percentage correct for each column.
%  act_by_cat          = cell array of the activations from A divided into the categories
%                        provided by Des(in left to right order)
% cowen 3/19/00

Est = zeros(size(A));
nsamples = size(Des,1);
% Find the maximums in each column and set them equal to 1
[m, i] = max(A');
for ii = 1:nsamples
  Est(ii,i(ii)) = 1;
end

sum_est = sum(Est);
if Rows(A) > 1
  n_correct_by_col = sum(Est.*Des);
else
  n_correct_by_col = Est.*Des;
end
n_correct        = sum(n_correct_by_col);  % total n correct
perc_correct     = n_correct/sum(sum_est); % total perc correct of total responses
% Avoid the divide by zero problem-- this will make
% the percent correct for a col with zero activation zero
sum_est(find(sum_est==0)) = inf;

perc_correct_by_col = n_correct_by_col./sum_est;

for ii = 1:size(Des,2)
  act_by_cat{ii} = A(find(Des(:,ii)==1),:);
end
