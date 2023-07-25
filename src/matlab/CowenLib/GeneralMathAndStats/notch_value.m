function [notchval, med,CI] = notch_value(D)
% The notches (if requested) extend to +/-1.58 IQR/sqrt(n). This seems to
% be based on same calculations as the formula with 1.57 in Chambers et al. (1983, p. 62)
% , given in McGill et al. (1978, p. 16). They are based on asymptotic 
%  normality of the median and roughly equal sample sizes for the two 
% medians being compared, and are said to be rather insensitive to the 
% underlying distributions of the samples. The idea appears to be to 
% give roughly a 95% confidence interval for the difference in two medians.
%
% Chambers, J. M., Cleveland, W. S., Kleiner, B. and Tukey, P. A. (1983)
% Graphical Methods for Data Analysis. Wadsworth & Brooks/Cole
% from
% http://www.stat.psu.edu/~dhunter/R/html/graphics/html/boxplot.stats.html
pctiles = prctile(D,[25;50;75]);
q1 = pctiles(1,:);
med = pctiles(2,:);
q3 = pctiles(3,:);
notchval = 1.57*(q3-q1)/sqrt(size(D,1));
n1 = med + notchval;
n2 = med - notchval;
if n1>q3, n1 = q3; end
if n2<q1, n2 = q1; end
CI(1,:) = n1;
CI(2,:) = n2;