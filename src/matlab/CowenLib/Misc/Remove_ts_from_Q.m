function [good_Q, bad_Q] = Remove_ts_from_Q(Qctsd, bad_times)
% 
% Remove the bins in Qctsd that are closest to the ts in bad_times.
%
% INPUT Qctsd
%       a list of timestamps
%
% OUTPUT: 
%       goodQ.spikes Q matrix of spikes not found in the bad list.
%       goodQ.times  A list of times associated with each spike.
%       badQ.spikes Q matrix of spikes found in the bad list.
%       badQ.times  A list of times associated with each spike.
%
% NOTE: because columns are being removed, the ctsd format is no
% longer appropriate(because it assumes regular and incremental
% times). As a result, this funciton returns the two Q matrices and
% the timestamps associated with the start of each bin as a structure.
%

% cowen Sun Apr 18 07:59:07 1999

dt = DT(Qctsd);
%T0 = StartTime(Qctsd);
Q.times = Range(Qctsd,'ts');
Q.mid_times = Q.times + round(dt*10/2); % find times closes to the middle of each bin 
                                        %REMEMBER ITS IN TIMESTAMPS
% This assumes the Q.times are the start times of each bin.
%error('d')

% Find the indices in Q that are closest to the timestamps in
% bad_times
thresh = dt*10;
V = zeros(1,length(bad_times));
for badtime = 1:length(bad_times)
  V(badtime) = binsearch(Q.mid_times,bad_times(badtime));
  % Don't include indices that are not even close to the spikes(not
  % within thresh dts.)
  if abs(Q.mid_times(V(badtime)) - bad_times(badtime)) > thresh
    V(badtime) = 0;
  end
end
% Construct the Q structures


% Remove indices that are not even close to the spikes(not within 2 sec.)
%for ii = bad_idx
%  if abs(Q.mid_times(bad_idx) - bad_times(bad_idx(ii))) > 20000
%%    bad_idx(ii) = 0;
%  end
%end
bad_idx = unique(V);
% No point in keeping the 0s
bad_idx(find(bad_idx==0)) = [];
disp(['Removed ' num2str(length(bad_idx)) ' elements'])
Q.spikes = Data(Qctsd)';
bad_Q.spikes =  Q.spikes(:,bad_idx);
bad_Q.times  =  Q.times(bad_idx);

all_idx = 1:length(Q.times);
good_idx = setdiff(all_idx, bad_idx); % The ones not in the bad indices
good_Q.spikes = Q.spikes(:,good_idx);
good_Q.times = Q.times(good_idx);
%error('e')