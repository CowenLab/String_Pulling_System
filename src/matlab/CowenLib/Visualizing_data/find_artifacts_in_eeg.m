function times = find_artifacts_in_eeg(eeg_list, start_and_end_ts ,window_size_sec, step_size_sec)
% Given a list of eeg files, display them and then step through
% Allow the user to mark the times when you have artifact.
sFreq = 10;
window_size_idx = sFreq*window_size_sec;
step_size_idx = sFreq*step_size_sec;
[T, EEG_data] = Read_CR_files(eeg_list, sFreq, start_and_end_ts);
T = T/1e6;
EEG_data = Z_Scores(EEG_data);
figure
keep_going = 1;
start_idx = 1;
end_idx = window_size_idx;
start_time = [];
times = [];
while keep_going
    if end_idx < Rows(EEG_data)
        plot(T(start_idx:end_idx),EEG_data(start_idx:end_idx,:) + repmat([1:size(EEG_data(start_idx:end_idx,:),2)]*4,size(EEG_data(start_idx:end_idx,:),1),1))
        xlabel(['Time from start ' num2str((T(start_idx) - start_and_end_ts(1)/1e6)/60) ' min'])
        
        axis tight
        drawnow
        x = ginput(1);
        a = axis;
        if x(1) > a(2)
            start_idx = start_idx + step_size_idx;
            end_idx = end_idx + step_size_idx;
        elseif x(1) < a(1)
            start_idx = start_idx - step_size_idx;
            end_idx = end_idx - step_size_idx;
        elseif x(2) < a(3)
            % Undo the last one.
            start_time = [];
        elseif x(2) > a(4)
            % Undo the last one.
            sortrows(times);
            times = times * 1e6;
            return
        else % Assume you set a start time or an end time.
            hold on
            plot([x(1) x(1)],[a(3) a(4)]);
            drawnow
            hold off
            if isempty(start_time)
                start_time = x(1);
            else
                times = [times; start_time x(1)];
                start_time = [];
            end
        end
    else
        keep_going = 0;
        disp('You reached the end')
    end
end
