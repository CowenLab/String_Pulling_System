function [GOODIX, start_end_ix] = Find_intervals_by_time(t,min_streak_length,min_diff_t)
% Looks for a series of timestamps that have a miniumum duration between
% points and also have a given number of 'contiguous' times (as specified
% by min_diff_t.
% cowen 2016
streak_count = 0;
GOODIX = false(size(t));
for ii = 2:length(t)
    d = t(ii)-t(ii-1);
    if d < min_diff_t
        streak_count = streak_count + 1;
    else
        if streak_count >= min_streak_length
            GOODIX((ii-streak_count):ii) = true;
        end
        streak_count = 0;
    end
end
if streak_count >= min_streak_length
    GOODIX((ii-streak_count):ii) = true;
end
% 
dIX = diff([0;GOODIX(:);0]);
IXup = find(dIX == 1);
IXdown = find(dIX == -1);
start_end_ix = [IXup IXdown];

