function [R, new_intervals_usec, r_idx] = CSC_to_r_matrices(eeg_files, intervals_usec, filter_type, filter_cutoff_Hz);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [R, file1_file2, new_intervals_usec, r_idx] = CSC_to_r_matrices(eeg_files, intervals_usec, filter_type, filter_cutoff_Hz);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%   eeg_files = a cell array of eeg files.
%   intervals_usec = a nintervals x 2 matrix of times of the start and end of each interval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT:
%   r = a n_unique_combos of files X n intervals matrix of the corrcoef.
%    the next one should be xcorr matrices and coherence matrices.
%  file1_file2 = the file combos that make up each correlation.
%  new_intervals_usec = the real intervals used (they may not be the same 
%  as the passed in intervals due to irregularities in the block sizes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  cowen 2003
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    filter_type = {'none'};
end
if nargin < 4
    filter_cutoff_Hz = [];
end
%sFreq = max(filter_cutoff_Hz)*2.8; % Get a bit above Nidquidst.
%disp(['Loading the data at ' num2str(sFreq) ' Hz']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~iscell(filter_type)
    tmp = filter_type;
    clear filter_type;
    filter_type{1} = tmp;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filter_order = 10;                            % This looks fine for butterworth in sptool, at least for sfreq at 2461.
n_files = length(eeg_files);
r_idx = find(triu(ones(n_files,n_files))==0); % Must be 0, else you get the diagonal as well as the off diag.
n_intervals = Rows(intervals_usec);    
new_intervals_usec = zeros(size(intervals_usec))*nan;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember('merged',filter_type)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Is merged means combine all of the EEG data in the intervals_usec
    % into one long vector and compute the R matrix with that.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    is_merged = 1;
    disp('Merging intervals for R matrix calculation.')
    R = zeros(length(r_idx),1)*nan;
else 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If false, compute an independent R matrix for each interval.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    is_merged = 0;
    disp('Computing R matrix for each interval.')
    R = zeros(length(r_idx),n_intervals)*nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%[T, EEG] = Read_nlx_CR_files(eeg_files,sFreq,intervals_usec);
% The following is hopefully outdated..
for interval_count = 1:n_intervals
    new_intervals_usec(interval_count,:) = [0 inf];
    for fc = 1:n_files
        ED = nlx2matCSC_Matrix(eeg_files{fc}, intervals_usec(interval_count,:));
        if fc == 1
            Fs = 1e6/(mean(diff(ED(:,1))));
        end
        new_intervals_usec(interval_count,1) = max([new_intervals_usec(interval_count,1), ED(1,1)]);
        new_intervals_usec(interval_count,2) = min([new_intervals_usec(interval_count,2), ED(end,1)]);
    end 
    fprintf('.');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
new_intervals_usec = round(new_intervals_usec);
fprintf('\n New Intervals (min): \n');
new_intervals_usec/1e6/60

if is_merged
    n_intervals = 1;
end

for interval_count = 1:n_intervals
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Just load the timestamps and then find the timestamps that are
    % in common to all files. Just load those times (some files will 
    % not have complete records.)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if is_merged
        % Load everything at once.
        ED  = nlx2matCSC_Matrix(eeg_files{1}, new_intervals_usec);
    else
        % Just load one interval so you have an R matrix for each.
        ED  = nlx2matCSC_Matrix(eeg_files{1}, new_intervals_usec(interval_count,:));
    end
    cED = zeros(Rows(ED),n_files)*nan;
    cED(:,1) = ED(:,2); % concatenate the current data to the cED{} 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for fc = 2:n_files
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if is_merged
            ED = nlx2matCSC_Matrix(eeg_files{fc}, new_intervals_usec); % load everything together.
        else
            ED = nlx2matCSC_Matrix(eeg_files{fc}, new_intervals_usec(interval_count,:));
        end
        cED(:,fc) = ED(:,2); % concatenate the current data to the cED{} 
        fprintf('interval: %i %i %i,   file: %i %s\n',interval_count, new_intervals_usec(interval_count,1) ,new_intervals_usec(interval_count,2),fc,eeg_files{fc})
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Filter the data and then do the analysis.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    for ii = 1:length(filter_type)
        switch filter_type{ii}
        case 'resample'   
            Fs = round(Fs);
            cED = resample(cED,max(filter_cutoff_Hz),Fs);
        case '60Hz'   
            [b,a] = butter(5, [55 65]/(Fs/2),'stop');
            cED = filtfilt(b,a,cED);
        case 'hipass'
            Cutoff_fq_Nq = filter_cutoff_Hz/(Fs/2);
            [b,a] = butter(filter_order,Cutoff_fq_Nq,'high');
            cED = filtfilt(b,a,cED);
            % RESAMPLE
            Fs = round(Fs);
            cED = resample(cED,filter_cutoff_Hz*2.4,Fs);
            Fs = filter_cutoff_Hz*2.4;
        case 'bandpass'   
            [b,a] = butter(5, filter_cutoff_Hz/(Fs/2));
            cED = filtfilt(b,a,cED);
            % RESAMPLE
            Fs  = round(Fs);
            newFs = round(max(filter_cutoff_Hz)*2.7);
            cED = resample(cED,newFs,Fs);
            Fs  = newFs;
        case 'lowpass'   
            Cutoff_fq_Nq = filter_cutoff_Hz/(Fs/2);
            [b,a] = butter(filter_order,Cutoff_fq_Nq);
            cED = filtfilt(b,a,cED);
            % RESAMPLE
            Fs = round(Fs);
            cED = resample(cED,filter_cutoff_Hz*2.4,Fs);
            Fs = filter_cutoff_Hz*2.4;
        case {'none' 'merged'}
            % do nothing
        otherwise
            error('BAD FILTER TYPE SWITCH')
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate the corrcoef
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    C = corrcoef(cED);
    R(:,interval_count) = C(r_idx);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(1,2,1)
    imagesc(C)
    title(num2str(interval_count))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(1,2,2)
    imagesc(cED)
    title(num2str(interval_count))
    drawnow
end
