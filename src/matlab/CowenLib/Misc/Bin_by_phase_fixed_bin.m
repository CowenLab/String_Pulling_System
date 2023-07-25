function [st_ed_t, Q] = Bin_by_phase_fixed_bin(S, TP, phase, bin_width)
% function [st_ed_t, Q] = Bin_by_phase_fixed_bin(S, TP, phase, bin_width)
% INPUT:
%   S = cell array or vector of timestamps
%   TP = 2 col matrix - time and phase. Be sure to have enought time
%   resolution appropriate for your data. I would say 100 pts per cycle.
% 
%   phase: the phase at which to center the binning.
%   bin_width: the width in time units (of S and TP) 
%
% OUTPUT:
%   Start and end times (in S time) for the start and end of each bin.
%   Q = binned times for each cell in the cell array or vector S.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Cowen 2020.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PLOT_IT = false;
% Create a master vec of all timestamps.

if iscell(S)
    T = [];
    for ii = 1:length(S)
        T = [T;S{ii}];
    end
    T = unique(T);
else
    T = unique(S);
end
V = circ_dist(TP(:,2),phase-pi); % why do I need to subtract 180degrees? If not it's pi off. Why?

ph_IX = V(1:end-1)>0 & V(2:end)<=0;
% eliminate times that are too close together (within 1/2 bin width apart).
t = TP(ph_IX,1);
IX = 1;
while any(IX)
    IX = diff(t)<bin_width;
    t = t(~IX);
end
st_ed_t(:,1) = t-bin_width/2;
st_ed_t(:,2) = t+bin_width/2;
% eliminate overlapping bins.
IX = st_ed_t(1:end-1,2) > st_ed_t(2:end,1);
while any(IX)
    fprintf('>> Bin_by_phase_fixed_bin: %d overlapping bins.\n',sum(IX));
    st_ed_t = st_ed_t(~IX);
    IX = st_ed_t(1:end-1,2) > st_ed_t(2:end,1);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now that we have the start and end times, we can bin the Q matrix.
% st_ed_t = Interval_merge(st_ed_t);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Q = Bin_ts_array(S,st_ed_t);
if sum(Q(:))/length(T) < .5
    disp('WARNING: More than 50% of spikes eliminated!')
end
if PLOT_IT
    Ta_r = Restrict(T,st_ed_t);
    ph   = interp1(TP(:,1),TP(:,2),T,'nearest');
    ph_r = interp1(TP(:,1),TP(:,2),Ta_r,'nearest');
    ph_t = interp1(TP(:,1),TP(:,2),t,'nearest');
    %     ang  = circ_mean(ph);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    figure
    subplot(1,3,1)
    polarhistogram(ph);
    subplot(1,3,2)
    polarhistogram(ph_r);    
    subplot(1,3,3)
    polarhistogram(ph_t);
end
