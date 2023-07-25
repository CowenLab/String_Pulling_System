function [LFP, bad_recIDs, ix, all_bad_ix] = detrend_LFP_artifact(LFP,thresh, samples_after_thresh_to_detrend, samples_after_to_ignore)
%function [LFP, bad_recIDs, ix] = detrend_LFP_artifact(LFP,thresh,samples_after_thresh_to_detrend, samples_after_to_ignore)
%
% perform a local (piecewise) detrend around the times in which there 
% was a large transition in the LFP produced by something like an artifact.
%
% Process- find abs(diffs) > thresh. Assume these are bad times. For intervals
% between these times and these times + samples-after_thresh_to_detrend,
% run a local detrending (using detrend). Also, ignore points near the
% artifact for this process as specified by samples_after_to_ignore.
% samples_after_thresh_to_detrend determines the detrending window. This is
% basically how long you believe the artifact typically lasts. 
%
% NOTE: this routine subtracts the median from the data prior to detrending. 
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bad_recIDs = find(abs(diff(LFP))> thresh);
end_recIDs = bad_recIDs + samples_after_thresh_to_detrend;
bad_recIDs_after_blank = bad_recIDs + samples_after_to_ignore;

LFP = LFP - median(LFP);

ix = [bad_recIDs(:); bad_recIDs_after_blank(:); end_recIDs(:)];
%O = detrend(LFP,'linear',ix); % this does not work for big datasets
% betcause the matlab implementation of detrend piecewise is stupid as 
% it requires a n by number of breakpoints matrix which is HUGE..
% so do it my way. for loops. ugh.
ix = unique([1;ix;length(LFP)]);
ix = ix(ix < length(LFP));
% loop through each break point and detrend.
for ii = 1:(length(ix)-1)
    LFP(ix(ii):ix(ii+1)) = detrend(LFP(ix(ii):ix(ii+1)),'linear');
end

for ii = 1:length(bad_recIDs)
    
    if bad_recIDs(ii) + samples_after_to_ignore < length(LFP)
        LFP(bad_recIDs(ii):(bad_recIDs(ii) + samples_after_to_ignore)) = 0;
    end
end


if nargout > 3
    all_bad_ix = [];
    for ii = 1:length(bad_recIDs)
        all_bad_ix = [all_bad_ix bad_recIDs(ii):end_recIDs(ii)];
    end
end
