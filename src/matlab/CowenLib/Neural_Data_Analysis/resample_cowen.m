function O = resample_cowen(LFP, sFreq, desired_sFreq)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function O = resample_cowen(LFP, sFreq, desired_sFreq)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ASSUMES LFP is a 2 COL matrix wiht the 1st col being time in usec and the
% second being the data.
% OUTPUT is a 2col matrix of time and samples.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isempty(sFreq)
    sFreq = 1e6/median(diff(LFP(:,1)));
end
O  = resample(LFP(:,2),desired_sFreq,round(sFreq));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EMGstd = decimate(EMGstd,100/sFreq);
interval_usec = 1e6/desired_sFreq;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Given that we have changed the sample size - the last timestamp of the
% resampled data will be a little smaller than the timestamp in the
% original data (by interval_usec).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
new_ts_usec = linspace(LFP(1,1),LFP(end,1)-interval_usec,length(O));
O = [new_ts_usec(:) O(:)];
