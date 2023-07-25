function [b,bint,r,rint,stats] = regress_cowen(X,y)
% function [b,bint,r,rint,stats] = regress_cowen(X,y);
% I wrote this because I am always annoyed by the input formatting of the
% regress command. I did modify the stats output to be sane
% see regress for help
% Cowen 2016
X = [ones(size(X,1),1) X];
[b,bint,r,rint,tmp] = regress(y,X);
stats.Rsq = tmp(1);
stats.F = tmp(2);
stats.p = tmp(3);
stats.err = tmp(4);
