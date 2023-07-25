function [p,F,residuals] = anova1_R(d,g)
% Perform an ANOVA on the data d by factors 
%   g (a vector of class IDs)
%
% Clean out the Nans if there are any
% cowen (2006)
good_ix = find(~isnan(d));
d = d(good_ix);
g = g(good_ix);
if length(d) < 6
    disp('Too few data points')
    p = nan;
    F = nan;
    residuals = nan;
end
putRdata('d',d);
putRdata('g',g);
evalR('g <- factor(g)');
evalR('ResMedNoint<-lm(d~g)');
%evalR('ResMedNoint<-aov(d~g)');
evalR('a<-anova(ResMedNoint)');
evalR('p<-a$Pr[1]');
evalR('F<-a$F[1]');
%p = getRdata('unclass(a$Pr[1])');
p = getRdata('p');
F = getRdata('F');
if nargout > 2
    evalR('residuals<-ResMedNoint$residuals');
    residuals = getRdata('residuals');
end
if nargout == 0
    %evalR('layout(matrix(c(1,2,3,4),2,2))');
    %evalR('plot(ResMedNoint)');
    evalR('boxplot(d~g)');  
end
%evalR('boxplot(d~g)');
%  interaction.plot(duration,weightgn,t;rans
