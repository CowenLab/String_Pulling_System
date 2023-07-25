function [p] = binomial_test_cowen(n_heads, total_flips, baseline_prob)
% Determine the probability of flipping a coin heads n_heads time in a row
% for total_flips tries. ASSUMES UNBIASED FLIPPING!!!
%
% Cowen 2011. See http://udel.edu/~mcdonald/statexactbin.html
if nargin < 3
    baseline_prob = 0.5;
end
for ii =1:length(n_heads)
    if n_heads(ii) > total_flips(ii)/2
        n_heads(ii) = total_flips(ii) - n_heads(ii);
    end
end
p = binocdf(n_heads,total_flips,baseline_prob);