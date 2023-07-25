function [first_in_burst, durations, n_per_burst, burst_id] = Burst_detector(T, interval_thresh, min_spikes_per_burst, second_interval_thresh)
% INPUT: 
%   T =  a ts object, a vector of timestamps, or a ts array
%   interval_thresh = interspike interval that is the maximum to consider in a burst
%   min_spikes_per_burst = number of spikes needed for a 'burst' like event to be considered a 
%                          burst. If 1 is specified then single spikes without any
%                          neighboring spikes will be considered a 'burst'.
%
% OUTPUT:
%   NO CONVERSIONS OF TIMES ARE MADE. THE SAME TIME UNITS GOING IN (AS A THRESH) ARE 
%   THOSE COMING OUT.
%   first_in_burst = timestamp of the first spike of a burst
%   durations = duration of each burst
%   n_per_burst  = the number of spikes per burst.
%   burst_ids = the burst id (1:inf) for each spike in T.
% Cotterill, E., & Eglen, S. J. (2019). Burst Detection Methods. Advances in Neurobiology, 22, 185–206. https://doi.org/10.1007/978-3-030-11135-9_8
if nargin < 4
    % This is for Grace and Bunny approach.
    second_interval_thresh = [];
end

% cowen

if isa(T,'ts')
    T = Data(T);
elseif isa(T,'cell')
    for ii = 1:length(T)
        if ~isempty(Data(T{ii}))
            if nargout == 0;
                figure
                Burst_detector(Data(T{ii}),interval_thresh, min_spikes_per_burst);
            else
                [first_in_burst{ii}, durations{ii}, n_per_burst{ii}, burst_id{ii}] = Burst_detector(Data(T{ii}),interval_thresh, min_spikes_per_burst);
            end
        else
            first_in_burst{ii} = 0; durations{ii} = 0; n_per_burst{ii} = 0; burst_id{ii} = 0;
        end
    end
    return
end
T = T(:); 
first_in_burst = [];
durations = [];
n_per_burst = [];
burst_id = [];
if length(T) < 5
    return
end

diffs = [0;diff(T(:))];

burst_counter = 1;
burst_id = zeros(size(T))*nan;
if isempty(second_interval_thresh)
    for ii = 1:length(diffs)
        % Go until you reach the end of a burst.
        if diffs(ii) > interval_thresh
            burst_counter = burst_counter + 1;
        end
        burst_id(ii) = burst_counter ;
    end
else
    % This is the Grace and Bunny approach - A different thresh (bigger) to
    % get out of a burst.
    in_burst = false;
    for ii = 1:length(diffs)
        if ~in_burst && diffs(ii) <= interval_thresh
            in_burst = true;
        elseif in_burst && diffs(ii) <= second_interval_thresh
            in_burst = true;
        else
            in_burst = false;
            burst_counter = burst_counter + 1;
        end
        burst_id(ii) = burst_counter ;
    end
end
n_per_burst = histcounts(burst_id, 1:max(burst_id));  %
id_diffs = [inf;diff(burst_id)];               %
first_in_burst = T(id_diffs > 0 );  
last_diffs = [diff(burst_id);inf];             %
%
last_in_burst  = T(last_diffs > 0 );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Eliminate those spikes that do not meet the 
% min_spikes_per_burst criterion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
IX =n_per_burst >= min_spikes_per_burst ;
n_per_burst = n_per_burst( IX );
first_in_burst = first_in_burst( IX );
last_in_burst = last_in_burst( IX );
durations = last_in_burst - first_in_burst;

if nargout == 0
    % Plot a peth around the burst start points.
    if ~isempty(first_in_burst)
        Align_spike_times(T,first_in_burst,2,2000,2000)
    else
        disp('No Bursts')
    end
end
