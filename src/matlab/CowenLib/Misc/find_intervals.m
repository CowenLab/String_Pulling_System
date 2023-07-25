function [above_times, below_times,above_IX,below_IX] = find_intervals(TX, thresh, lower_thresh, minimum_duration, minimum_inter_interval_period)
% Finds intervals in a record TX (time and data) that are above
% or below the specified threshold.
%
% INPUT: TX nx2 matrix where col1 is time, col 2 is data. OR TX is a vector
%          This should be a
%          smoothed energy trace of the data you wish to threshold.
%        thresh - threshold. If a 2-element vector, then the second value
%        is assumed to be a rejection level- ignore points with  this
%        value. 
%        low_thresh - 
%          * if a value is specified: move out from the identified start end times until
%             you fall below the low_thresh. This allows you to set a higher
%             threshold for event detection, and still retain a good estimate
%             of the event onset time.
%          * if a nan, then move out in either direction until the first
%             derivative changes. Threshold free - which is nice.
%          * if empty, then don't do anything.
%        minimum_duration - the minimum duration of an event to be
%         considered above threshold.
%        minimum_inter_interval_period = if an interval between two
%         super-threshold periods is this small, merge them together.
%
% OUTPUT: start and end times for periods above or below the threshold.
%
% This is useful for code like theta or spindle detection.
%
%  TODO: seems to be a problem when the passed in data are all negative -
%  it reverses the order of hte start and end times i believe.
% original in 2006.
% Cowen 2023 minor fixes
if min(size(TX)) == 1
    TX = [[1:length(TX)]' TX(:)];
end
if ~isa(TX,'double')
    TX = double(TX);
end
if nargin <3
    lower_thresh = [];
    minimum_duration = [];
end
if nargin < 4
    minimum_duration = [];
end    
if nargin < 5
    minimum_inter_interval_period = [];
end
TX(1,2) = 0; % This allows it to register up times when the record STARTs above threshold
TX(end,2) = 0; % This allows it to register up times when the record ENDs above threshold
if numel(thresh) == 2
    % mark points that are too high with 0 so that they will not be
    % detected. 
    TX(TX(:,2) >= thresh(2),2) = 0;
    thresh = thresh(1); 
end

cross_points = diff(TX(:,2) > thresh); % Apply the threshold - append 0 to front and end
above_times  = [TX(cross_points == 1,1) TX(cross_points == -1,1)];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Expand out the definition of an interval to points where the data crosses
% a lower threshold.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isnan(lower_thresh)
    % Move out or forward until the first derivative changes.
    new_above_times = above_times;
    all_start_ix = binsearch_vector(TX(:,1), above_times(:,1));
    all_end_ix = binsearch_vector(TX(:,1), above_times(:,2));
    for ii = 1:size(above_times,1)
        % move the threshold out to the point where the 1st derivative
        % changes.
        ix = all_start_ix(ii);
        while (ix > 0 && TX(ix,2) <= TX(ix+1,2) )
            ix = ix - 1;
        end
        if ix > 0
            new_above_times(ii,1) = TX(ix,1);
        end
  
        ix = all_end_ix(ii);
        while (ix < size(TX,1) && TX(ix,2) <= TX(ix-1,2) )
            ix = ix + 1;
        end
        new_above_times(ii,2) = TX(ix,1);
    end
    % Get rid of the overlapping intervals.
    % There is proably a 1 line command for this but I couldn't think of
    % it.
    for ii = 1:(size(new_above_times,1)-1)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % IF START OF THE FUTURE EVENT IS BEFORE THE PREVIOUS, MARK FOR
        % MERGER. mark the end and future start times for deletion.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if new_above_times(ii+1,1) <= new_above_times(ii,2)
           new_above_times(ii+1,1) = nan;
           new_above_times(ii,2) = nan;
        end
    end
    % Cowen 2023 - fixed an error here that reversed start and end
    % sometimes (not all the time)
    new_above_times(isnan(sum(new_above_times,2)),:) = [];
    above_times = new_above_times;
elseif ~isempty(lower_thresh)
    % Apply a second lower threshold to identify the true start time and
    % end time.
    if lower_thresh > thresh
        error ('Low threshold must be LOWER than the threshold')
    end
    new_above_times = above_times;
    all_start_ix = binsearch_vector(TX(:,1), above_times(:,1));
    all_end_ix = binsearch_vector(TX(:,1), above_times(:,2));
    for ii = 1:size(above_times,1)
        % move the threshold out to the lower end of the detection threshold.
        ix = all_start_ix(ii);

        while (ix > 0 && TX(ix,2) > lower_thresh )
            ix = ix - 1;
        end
        new_above_times(ii,1) = TX(ix,1);
        % Attempting a speed improvement... I don't think it helps.
        %TX = TX(ix:end,:);
        
        ix = all_end_ix(ii);
        while ( ix < size(TX,1) && TX(ix,2) > lower_thresh )
            ix = ix + 1;
        end
        new_above_times(ii,2) = TX(ix,1);
    end
    % Get rid of the overlapping intervals.
    % There is proably a 1 line command for this but I couldn't think of
    % it.
    for ii = 1:(size(new_above_times,1)-1)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % IF START OF THE FUTURE EVENT IS BEFORE THE PREVIOUS, MARK FOR
        % MERGER. mark the end and future start times for deletion.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if new_above_times(ii+1,1) <= new_above_times(ii,2)
           new_above_times(ii+1,1) = nan;
           new_above_times(ii,2) = nan;
        end
    end
    new_above_times(isnan(sum(new_above_times,2)),:) = [];
    above_times = new_above_times;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Remove those times that aren't long enough to be reasonably considered an
% interval.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(minimum_inter_interval_period)
    % Merge inter-interval-intervals that are too short to be reasonable.
    new_above_times = above_times;
    d_times = above_times(2:end,1) - above_times(1:end-1,2);
    idx = find(d_times < minimum_inter_interval_period);
    new_above_times(idx,2) = nan;
    new_above_times(idx+1,1) = nan;
    new_above_times(isnan(sum(new_above_times,2)),:) = [];
    above_times = new_above_times;
end

if ~isempty(minimum_duration)
    goodix = (above_times(:,2) - above_times(:,1)) >  minimum_duration;
    above_times = above_times(goodix,:);
end

if nargout > 1
    % Times when not above threshold.
    below_start_times = unique([TX(1,1); above_times(:,2)]);
    below_end_times   = unique([above_times(:,1); TX(end,1)]);
    below_times = [below_start_times below_end_times];
    d = below_times(:,2)-below_times(:,1);
    below_times = below_times(d>0,:);
    if Rows(below_times) > 1 
        if below_times(1,1) == below_times(2,1) 
            below_times(1,:)= [];
        end
        if below_times((end-1),2) == below_times(end,2)
            below_times(end,:)= [];
        end
    end
end
if nargout > 2
    % return the indices as this can also be useful.
    [~,above_IX] = Restrict(TX,above_times);
    [~,below_IX] = Restrict(TX,below_times);
end
if nargout == 0
    % Validate this...
    figure
    plot(TX(:,1),TX(:,2));
    plot_markers_simple(above_times(:,1),[],[],'g')
    plot_markers_simple(above_times(:,2),[],[],'r')
end

