function EVT = Events_from_transition_times(Times, bit_interval, within_rec_interval)
% The way we are sending events to the acquisition channel is through the
% EEG system. This is half ass, but it's all we've got (well, I could
% sacrifice a stereotrode as well). This function reads the EEG data and
% spits out the event times and codes in a 2 column matrix.
%
% INPUT: 2 column matrix of time and the unfiltered EEG event stream.
% OUTPUT: 2 Column matrix of event time and code.
%
% Cowen
% Find the values > 1000 - these are the events
% I only pay attention to the upward transitions .
if nargin < 2
    bit_interval = 80;
end
if nargin < 3
    within_rec_interval = 175;
end
Times = Times(:);
diffs = [diff(Times);nan];
EVT = [];
keep_going = true;
count = 1;
while keep_going
    first_ix = count;
    count1 = 1;  
    while diffs(count) < bit_interval
        count1 = count1 + 1;
        count = count + 1;
    end
    
    if diffs(count) > within_rec_interval
        % Store event and go to the next event.
        EVT = [EVT; Times(first_ix) count1*10 ];
    elseif diffs(count) <= within_rec_interval
        % There is a second block to this record so at least one pulse. 
        count2 = 1;
        count = count + 1;
        while ~isnan(diffs(count)) && diffs(count) < bit_interval  
            count2 = count2 + 1;
            count = count + 1;
        end
        EVT = [EVT; Times(first_ix) count1*10 + count2];
        
        if isnan(diffs(count))
            keep_going = false;
        end
    elseif isnan(diffs(count))
        keep_going = false;
    else
        error('I dont know what happened')
    end
    count = count + 1;
end
%sdisp('')