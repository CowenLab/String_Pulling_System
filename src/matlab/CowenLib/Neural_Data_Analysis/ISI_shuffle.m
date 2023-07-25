function [Tshuff, T]= ISI_shuffle(T, intervals);
%function [Tshuff, S]= ISI_shuffle(S, intervals);
%
% Shuffle the times in the vector T (or cell array of vectors - timestamps) by shuffling
% the order of the intervals between spike times.
%
% OPTIONAL: intervals = pass in a nx2 matrix of start and end intervals (for example:
% ripple intervals). A separated ISI shuffle is then completed for each
% interval. The shuffled ISI  and the restricted original unshuffled timestamps (S)
% are returned.
%
% cowen 2006
if nargin == 1
    intervals = [];
end
Tshuff = [];
if isempty(T)
    return
end

if iscell(T)
    % Do it for each cell in the cell array
    for ii = 1:length(T)
        T{ii} = ISI_shuffle(T{ii}, intervals);
    end
    return
end
if length(T)==1 
    % Don't bother if 2 spikes.
    Tshuff = T;
elseif length(T)==2
    % If 2 spikes, just randomize the interval.
    Tshuff = T + randn(1,1) * diff(T);
else
    if isempty(intervals)
        Tshuff = zeros(size(T))*nan;
        d = diff(T);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Make sure the start and end time are also random by choosing a
        % random interval from the passed in intervals and subtract it from
        % the second timestamp to get the first timestamp.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        r = floor(rand(2,1)*length(d))+1;
        Tshuff(1) = T(2)-d(r(1)); % subtract from second time
        d(end) = d(r(2)); % Choose a random interval for the end time.
        Tshuff(2:end) = Tshuff(1)+cumsum(d(randperm(length(d))));
    else
        % compute the shuffle independently for each interval.
        [r,c] = size(T);
        if c>r
            T = T(:);
        end
        Tshuff = []; S = [];
        for iInterval = 1:rows(intervals)
            goodix = find(T >= intervals(iInterval,1) & T <= intervals(iInterval,2));
            if ~isempty(goodix)
                if 0
                    % Shuffle the spikes AND the start and end of interval (so we
                    % have 2 extra intervals to shuffle) and then remove those two
                    % extra spikes (from the start and end time) randomly from the
                    %%%%%%%%%%%%%
                    % NOTE: I don't like this as much as my current way of
                    % doing this - of changing the start and end time by
                    % randomly selecting an interval from the ISI's that were
                    % passed in. (see the code above)
                    %%%%%%%%%%%
                    t = ISI_shuffle([intervals(iInterval,1); V(goodix); intervals(iInterval,2)]);
                    rp = randperm(length(t));
                    Tshuff  = [Tshuff ; t(rp(1:length(goodix))) ];
                else
                    Tshuff  = [Tshuff ; ISI_shuffle(T(goodix))];
                end
                S = [S; T(goodix)]; % original spikes
            end
        end
        Tshuff = sort(Tshuff);
        T = sort(S);
        if c>r
            % return the times to the original configuration.
            T = T';
            Tshuff = Tshuff';
        end
    end
end