function [rsq, p, t]= stim_specificity_erickson(V,G);
% INPUT:
%  V = a vector of binned spike counts (say 1 per trial)
%  G = the group member of each bin (say stimulus or trial type)
% OUTPUT:
%  rsq = The Erickson and Desimone measure of stimulus specificy of the neuron.
%  The Journal of Neuroscience, December 1, 1999, 19(23):10404-10416
%    they ref a stats book... (Keppel and Zedeck, 1989).
%A measure of stimulus selectivity (r2) was calculated from the ANOVA table
% for each neuron by simply dividing the sum of squared deviations for the 
% treatment by the total sum of squared deviations from the grand mean (Keppel and Zedeck, 1989).
% The R2 statistic provides an estimate of how much of the variance in firing 
% rate can be accounted for by specific stimuli and, unlike F ratios and p values,
% is not influenced by sample size. The normalized magnitude of the neuronal 
% response was measured by computing a z score for each stimulus relative to 
% the distribution of baseline firing rates.Journal of Neuroscience,
% December 1, 1999, 19(23):10404-10416
% cowen 2005
if std(V) == 0
    rsq = 0;
    p = 1;
    t = [];
    return
end
[p,t] = anova1(V,G,'off');
rsq = t{2,2}/(t{4,2}+eps);
