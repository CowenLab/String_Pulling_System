function [M, x_axis, align_ix] = Align_on_continuous_events(t_D,ITI,alignment_times, time_before, time_after)
% units are whatever you want.
% See PETH_eeg and PETH_eeg_simple - They may supercede this.
% 
if isempty(ITI)
    ITI = median(diff(t_D(:,1)));
end
[nSamples,nDims] = size(t_D);
nDims = nDims - 1;
x_axis = -time_before:ITI:time_after;
points_in_window = length(x_axis);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%time_before_ts = time_before*10; % Assumes old cheetah TimeStamps_us
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Align the TimeStamps_us by subtracting the point time from each record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_alignments = length(alignment_times);
M = zeros(n_alignments,points_in_window,nDims)*nan;
prev_idx = 1;
align_ix = zeros(n_alignments,1);
for ii = 1:n_alignments
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Ignore points that go beyond the range
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if 1
        if ((alignment_times(ii) - time_before) >= t_D(1,1)) & prev_idx < nSamples
            % Recall, there may be overlapping timestamps as one window may overlap with another. As a result
            % it necessary to take the LARGEST index that matches the timestamp. Thus, we need to use
            % binsearch only on the data following the previous find. This may even speed things up.
            % the new way. This ensures you only look at the data after the previous window so that
            % there is no overlap. This should also speed things up considerably.
            % The alternative is to just do this... idx = binsearch(EEG_data(:,1), alignments_ts(ii) - time_before);
            idx = binsearch(t_D(prev_idx:end,1), alignment_times(ii) - time_before);
            idx = idx + prev_idx - 1;

            %prev_idx = idx + points_in_window - 1;
            % Was above, then I changed it.
            prev_idx = idx;
            if idx+points_in_window <= nSamples
                % Ignore points that go beyond the range
                for iD = 1:nDims
                    M(ii,:,iD) = t_D(idx:(idx+points_in_window-1),iD+1)';
                    % The alternative to this is to interpolate with interp1. I
                    % haven't tried this though.
                end
            end
            align_ix(ii) = idx;
        else
            disp('WARNING: COULD NOT FIND INTERVAL IN THE DATA-- INTERVAL OUT OF RANGE')
        end
    else
        % This is the simplest way to do this. IT may be slower though.
        % It is a good check for accuracy.
        ix = binsearch(t_D(:,1),alignment_times(ii));
        tmpt = t_D(:,1) - alignment_times(ii);
        for iD = 1:nDims
            M(ii,:,iD) = interp1(tmpt,t_D(:,iD+1) ,x_axis);
        end
    end

end
%$all_ix = repmat(align_ix(:),1,points_in_window) + repmat(0:(points_in_window-1),n_alignments,1);

%if idx+points_in_window <= nSamples
% Ignore points that go beyond the range
%    M(ii,:,1:nDims) = t_D(idx:(idx+points_in_window-1),2:end)';
%end

%ix = find(~isnan(M(:,1,1)));
%M = M(ix,:,:);
M = squeeze(M);