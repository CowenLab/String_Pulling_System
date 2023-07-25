function [It,Isp] = Skaggs_spatial_information(occ,f_rates,mean_rate)
% Compute the skaggs measure of spatial information for one cell (assuming 1D fields)
% occ- the amount of time spent in each bin locatio. This is converted to a
% probabilty distribution.
%
% NOTE: Both of these measures is affected by differences in firing rate
% (esp. It) and should be compared against a shuffle ISI distribution. See
% the original Skaggs papers which also do this. NOte: sparsity also is
% affected by rate.
%
% frates: the FIRING RATE (not count) within each spatial bin.
%
% mean_rate: the MEAN RATE during the running epoch used for analysis.
% DO NOT JUST AVERAGE OVER THE PF BINS. Imagine if you made the bin size
% infinitely small - you would push the average near zero 
%
% OUTPUT: the information over time (It) and the information per spike
% (Isp).
% For comparison between these two measures, you can see...
% Senzai Y, Buzsáki G (2017) Physiological Properties and Behavioral Correlates of Hippocampal Granule Cells and Mossy Cells. Neuron 93:691-704.e5.
% [actually, while the above does define these 2 measures, it does not compare]
% and the Zhang paper (below).
% pass in the occupancy at each location and the firing rate at each location.
% https://www.sciencedirect.com/science/article/pii/S0896627320305237?via%3Dihub
%  (Skaggs et al., 1993) 
% I is information per time, IAP is information per spike, i = 1, 2, ., N represents bin number, pi is the probability of occupancy of bin i, li is the firing rate in bin i, and l is the mean firing rate of the cell on the linear track (Skaggs et al., 1993, 1996; Senzai and Buzsa´ ki, 2017). T
%See An Information-Theoretic Approach to Deciphering the Hippocampal
% NOTE: A threshold used in Zhang X, Schlögl A, Jonas P. 2020. Selective Routing of Spatial Information Flow from Input to Output in Hippocampal Granule Cells. Neuron 107:1212-1225.e7.
% was For analysis of spatial tuning of APs, only recording epochs in which the mouse was running with a velocityR2cms-1 were analyzed. Cells were considered spatially tuned if their spatial information score (Skaggs et al., 1993) was statistically significant from shuffled controls and R 0.4 bits s-1. Spatial information was computed according to the equations
% Cowen 2021
%
occ = occ/nansum(occ); % should sum to 1.
It = nansum(occ.*(f_rates).*log2(f_rates/mean_rate));
Isp = nansum(occ.*(f_rates/mean_rate).*log2(f_rates/mean_rate));
