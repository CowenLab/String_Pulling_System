function [V]= Validate_reactivation(Reactivation_function,options, plot_it)
%
% Validate a measure of reactivation by measuring the strength of
% reactivation as a function of the strength of the signal to noise between
% behavior and rest.
%  INPUT: the function
%   the passed in reactivation function must take cell arrays of spike times.
%   where each element of hte array is a cell. options is  a cell array of
%   options to pass to the reactivation function.
%
%  This function will return the measure of reactivation as a function of
%  the S-N ratio between Behavior and Rest.
%  options - cell array of options to pass into the reactivation function.
%    these depend on the reactivation function.
%  plot_it - if 1 it plots a summary plot.
%
% OUTPUT:
%   V = col1 the sn ratio, col2 the strength of reactivation measure. col3
%   is the std.
%   Vbinsize  validates the algorithm against changes in binsize.
%   (optional)
%
% e.g. [V Vbinsize]= Validate_reactivation(@Reactivation_EV,{[20 20] })
% cowen 2006
if nargin < 3
    plot_it = 0;
end
nCells = 25;
nLevels = 6;
nPermutations = 7;
V = zeros(nLevels,3)*nan;
sn = linspace(0,1,nLevels);

for iLevel = 1:nLevels
    for iPermutation = 1:nPermutations
        [R1_spike_ca, x_tsd, y_tsd,pf_ctr] = Artificial_place_cells(60*5,nCells,[15*sn(iLevel) 15*(1-sn(iLevel))],1,.01,'random');
        [B_spike_ca, x_tsd, y_tsd,pf_ctr]  = Artificial_place_cells(60*5,nCells,[15 2],1,.01,pf_ctr);
        [R2_spike_ca, x_tsd, y_tsd,pf_ctr] = Artificial_place_cells(60*5,nCells,[15*sn(iLevel) 15*(1-sn(iLevel))],1,.01,pf_ctr);
        r(iPermutation) = Reactivation_function(R1_spike_ca,B_spike_ca,R2_spike_ca,options{:});
        fprintf('p')
    end
    V(iLevel,:) = [sn(iLevel) mean(r) std(r)];
    fprintf('.')
end
fprintf('\n')
if plot_it == 1
    errorbar(V(:,1),V(:,2),V(:,3))
    xlabel('Signal to noise during sleep')
    ylabel('Strength of reactivation')
end