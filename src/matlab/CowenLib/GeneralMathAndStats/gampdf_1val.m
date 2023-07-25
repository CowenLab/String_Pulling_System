function y = gampdf_1val(D);
% Returns the best fit values to a gamma function from the distribution of
% the data D.
%  - the gamma pdf is a somewhat close continuous version of the poisson
%  distribution.
%
%
% cowen
a = gamfit(D);
y = gampdf(D,a(1),a(2));
