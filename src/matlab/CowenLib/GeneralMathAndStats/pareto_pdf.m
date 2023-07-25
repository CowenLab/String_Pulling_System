function y = pareto_pdf(x,x_m,k)
% Pareto pdf function
% x = the points to calulate.
% x_m = the left side.
% k = pareto parameter 
% cowen 2006
% see http://en.wikipedia.org/wiki/Pareto_distribution
y = (k*x_m^k)./(x.^(k+1));
y = y ./ sum(y);
%./sum((k*x_m^k)./(x.^(k+1)));