function [st_ed_t, Q] = Bin_by_phase(S, TP, phase_range_rad, use_acute, interval_threshold)
% INPUT:
%   S = cell array or vector of timestamps
%   TP = 2 col matrix - time and phase. Be sure to have enought time
%   resolution appropriate for your data. I would say 100 pts per cycle.
% 
%   phase_range_rad = 2-element vector = range of phases to consider spikes per cycle. If not
%   provided, this is determined automatically.
%
% OUTPUT:
%   Start and end times (in S time) for the start and end of each bin.
%   Q = binned times for each cell in the cell array or vector S.
%  
%  Cowen.

% Create a master vec of all timestamps.
if nargin < 4
    use_acute = true;
end
if nargin < 5
    interval_threshold = [];
end

if iscell(S)
    T = [];
    for ii = 1:length(S)
        T = [T;S{ii}];
    end
    T = unique(T);
else
    T = unique(S);
end
Sph = nan(length(T),2);
PIX = false(length(TP),1);

% inefficient but easy...
for ii = 1:Rows(TP)
    %     if TP(ii,2)>= phase_range_rad(1) && TP(ii,2)<= phase_range_rad(2)
    % Assumes acute
    if is_angle_between(TP(ii,2),phase_range_rad(1),phase_range_rad(2),1)
       PIX(ii) = true;
    end
end
if ~use_acute
    PIX = ~PIX;
end
stedix = find_intervals_logical(PIX);
st_ed_t = nan(size(stedix));
st_ed_t(:,1) = TP(stedix(:,1),1);
st_ed_t(:,2) = TP(stedix(:,2),1);
if ~isempty(interval_threshold)
    GIX = (st_ed_t(:,2) - st_ed_t(:,1)) > interval_threshold(1) & (st_ed_t(:,2) - st_ed_t(:,1)) < interval_threshold(2);
    st_ed_t = st_ed_t(GIX,:);
    fprintf('elim %d bad intervals ',sum(~GIX))
end
% now that we have the start and end times, we can bin the Q matrix.
st_ed_t = Interval_merge(st_ed_t);

Q = Bin_ts_array(S,st_ed_t);
