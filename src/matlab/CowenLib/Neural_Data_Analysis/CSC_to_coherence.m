function [C, Fqs, new_intervals_usec, r_idx] = CSC_to_coherence(eeg_files, intervals_usec, frequency_intervals_Hz, option);
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
%  cowen 2004
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4
    option = {'none'};
end

if ~iscell(option)
    tmp = option;
    clear option;
    option{1} = tmp;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nfft = 256;   % For coherence
n_files = length(eeg_files);
r_idx = find(triu(ones(n_files,n_files))==0); % Must be 0, else you get the diagonal as well as the off diag.
[idx_rows idx_cols] = find(triu(ones(n_files,n_files))==0); % Must be 0, else you get the diagonal as well as the off diag.
n_intervals = Rows(intervals_usec); 
if isempty(n_freq_intervals)
    n_freq_intervals = nfft/2 + 1; % the output of cohere
else
    n_freq_intervals = Rows(frequency_intervals_Hz);
end
new_intervals_usec = zeros(size(intervals_usec))*nan;
% The coherence matrix. 
C = zeros(n_intervals,length(r_idx),n_freq_intervals);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember('merged',option)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Is merged means combine all of the EEG data in the intervals_usec
    % into one long vector and compute the R matrix with that.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    is_merged = 1;
    disp('Merging intervals for coherence calculation.')
    R = zeros(length(r_idx),1)*nan;
else 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If false, compute an independent R matrix for each interval.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    is_merged = 0;
    disp('Computing coherence for each interval.')
    R = zeros(length(r_idx),n_intervals)*nan;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

C = zeros(nfft
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

    %Fs = round(Fs);
    %cED = resample(cED,max(max(frequency_intervals_Hz))*2.4,Fs);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate the coherence between all channels
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Get rid of any 60Hz.
    if ismember('Filter_60Hz',option)
        [b,a] = butter(5, [55 65]/(Fs/2),'stop');
        cED = filtfilt(b,a,cED);
        disp('Filtered out 60Hz signal')
    end
    for ii = 1:16 
        rr{ii} = [ii+1]; 
    end
    rr{end} =1 ;
    cED = Decorrelate_matrix(cED,rr)
    for ii = 1:length(idx_rows)
        [C(interval_count,ii,:),Fqs] = cohere(cED(:,idx_rows(ii)), cED(:,idx_cols(ii)),[],Fs);
        fprintf('c');
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(1,2,1)
    imagesc(Fqs,[],squeeze(C(interval_count,:,:)))
    title(num2str(interval_count))
    set(gca,'YTick',1:length(idx_rows))
    set(gca,'YTickLabel', num2str([idx_rows(:) idx_cols(:)]))
    set(gca,'FontSize',6)
    xlabel('combo')
    ylabel('Fq')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    subplot(1,2,2)
    imagesc(cED)
    title(num2str(interval_count))
    drawnow
end
