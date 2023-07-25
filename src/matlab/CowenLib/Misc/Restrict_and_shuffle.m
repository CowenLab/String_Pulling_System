function [T, IDX, Ts] = Restrict_and_shuffle(I, start_ts, end_ts, method)
%function [T, IDX, T_shuff_within, T_shuff_across] = Restrict_and_shuffle(I, start_ts, end_ts)
%
% INPUT: 
%      I. A cell array of vectors of timestamps or a single double vector of timestamps.
%      start_ts and end_ts - the start and end valu to restrict the values of I.
%      - also shuffles the data within each interval (shuffles ISI's)
%      - and across intervals
%
% 
%  There are many ways to shuffle spike times and the method depends on the
%  question that you have in mind. Here is my list of the methods and their
%  applications.
%
%  'across_trials_dist_from_data' 
%      1. create a master list of ISI's for all spikes within all intervals.
%      2. go back through each interval, find the original spikes for that
%         interval (thus preserving the trial by trial firing rate) and add or
%         subtract a random ISI from the master distribution.
%      USES: this is useful for spike synchrony analysis as it minimizes the 
%              covariation due to precise spike timing and still preserves the 
%              original distribution of ISI's. XCorrs created from this distribution 
%              could be subtracted from the xcorrs created from the
%              original spike train. This approach also preserves the local
%              average changes in rate to a stimulus as the original spikes
%              are shifted left or right with the same probability so it
%              gives you information on stimulus responsiveness in the
%              absence of synchrony.
%
%  'rand_dist_rand_start'
%    for each interval, create a sequence of the same size as the original
%    (preserve within trial rate), but randomize the timing from a purely
%    poisson distribution (flat distribution of intervals)
%     USES: the simple poisson distribution is easy to interpret. This
%     eliminates any precise spike timing effects (for xcorr studies). On the other hand, it
%     strays from the actual distribution of the data (no AHP, etc...)
%
%  'data_dist_rand_start'
%    for each interval, create a sequence of the same size as the original
%    (preserve within trial rate), but reorder the ISI's and create a
%    random start time. This will also eliminate any precise spike timing
%    effects across cells. It also preserves the ISI distribution of the
%    original data.
%   
% OUTPUT:
%      same format as I, but with times outside of the start and end ts removed
%      IDX  are the indices in the original I of the restricted data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% similar to the restrict function for ts objects except the ts object version does not return idx.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if iscell(I)
    for ii = 1:length(I)
        [T{ii}, IDX{ii}, T_shuff_within{ii}, T_shuff_across{ii}] = Restrict(I{ii},start_ts,end_ts);
    end
else
    I = I(:);
    start_ts = start_ts(:);
    end_ts = end_ts(:);
    IDX = [];
    all_diff = [];
    for ii =1:length(start_ts)
        ix = find(I>=start_ts(ii) & I<=end_ts(ii));
        nSpikes(ii) = length(ix);
        if nSpikes(ii) > 0
            all_diff = [all_diff; diff(I(ix))];
            IDX = [IDX; ix];
        end
    end
    T = I(IDX);

    % Shuffle
    % Go through each interval and choose the same number of spikes as in
    % the original interval - preserving trial by trial changes in mean
    % spike count.
    Ts = zeros(sum(nSpikes),1);
    switch method
        case' across_trials_dist_from_data'
            all_diff = repmat(all_diff,4,1);
            all_diff(1:round(length(all_diff)/2)) = all_diff(1:round(length(all_diff)/2))*-1;
            all_diff = all_diff(randperm(length(all_diff)));
            % randomly change the sign
            lad = length(all_diff);
            for ii =1:length(start_ts)
                % Keep picking from the random distribution until you get a sample
                % that fits within the interval.
                ix = find(T>=start_ts(ii) & T<=end_ts(ii));
                for iS = 1:length(ix)
                    Ttmp = 0;
                    while Ttmp > end_ts(ii) | Ttmp < start_ts(ii)
                        rv           = all_diff(ceil(rand(1,1)*(lad-1)));
                        Ttmp = T(ix(iS)) + rv;
                    end
                    %
                    Ts(ix(iS)) = T(ix(iS)) + rv;
                end
            end
        case 'rand_dist_rand_start'
            for ii =1:length(start_ts)
                % Randomly choose a start time within the interval (flat
                % distribution of start times), but preserve the original
                % number of spikes.
                ix = find(T>=start_ts(ii) & T<=end_ts(ii));
                nspk = length(ix);
                interval = end_ts(ii) - start_ts(ii);
                starts = rand(nspk,1)*interval;
                Ts(ix) = start_ts(ii) + starts;
            end
        case 'data_dist_rand_start'
            for ii =1:length(start_ts)
                % Take the existing spikes in this interval, shuffle the ISI's 
                %  and then choose a random starting time for this new sequence.
                interval = end_ts(ii) - start_ts(ii);
                ix = find(T>=start_ts(ii) & T<=end_ts(ii));
                oldT = T(ix);
                nspk = length(oldT);
                %
                d = diff(oldT);
                d = d(randperm(length(d)));
                diff_seq = [0; cumsum(d)];
                slop = interval - sum(d);
                %
                newT = start_ts(ii) + rand(1,1)*slop + diff_seq;
                Ts(ix) = newT;
            end

        otherwise
            error('Incorrect method')
    end
    Ts = sort(round(Ts)); % sorts and removes duplicates.
end



