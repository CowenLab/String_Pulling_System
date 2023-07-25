function [R, new_intervals_usec, r_idx, ref_pairs] = CSC_to_r_matrices(eeg_files, sFreq, intervals_usec, option, option_parameters);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [R, new_intervals_usec, r_idx] = CSC_to_r_matrices(eeg_files, sFreq, intervals_usec, option, option_parameters);
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
    option = {'none'};
    option_parameters{1} = [];
end

disp(['Loading the data at ' num2str(sFreq) ' Hz']);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filter_order = 10;                            % This looks fine for butterworth in sptool, at least for sfreq at 2461.
n_files = length(eeg_files);
r_idx = find(triu(ones(n_files,n_files))==0); % Must be 0, else you get the diagonal as well as the off diag.
n_intervals = Rows(intervals_usec);    
new_intervals_usec = zeros(size(intervals_usec))*nan;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ismember('merged',option)
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
% In reality, I should really to the FFT on the non-segmented data
%  and then work with the result.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[T, EEG, ref_pairs] = Read_CR_files(eeg_files, sFreq, intervals_usec, option, option_parameters);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% We can treat all of these intervals as one and do the corrcoef
% between them all, or treat them individually.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the corrcoef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if is_merged
    C = corrcoef(EEG);
    R = C(r_idx);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ismember('plot', option)
        subplot(1,2,1)
        imagesc(C)
        title(num2str(interval_count))
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        subplot(1,2,2)
        plot(Z_scores(EEG(start_idx:end_idx,:)) + repmat([1:size(EEG,2)]*4,size(EEG,1),1))
        axis tight
        title(num2str(interval_count))
        drawnow
    end
else
    %Mn = [];
    for interval_count = 1:n_intervals
        % Find the start and end of the interval in the data.
        start_idx = binsearch(T,intervals_usec(interval_count,1));
        end_idx = binsearch(T,intervals_usec(interval_count,2));
    %    Mn = [Mn;EEG(start_idx:end_idx,1)'];
    %end
        C = corrcoef(EEG(start_idx:end_idx,:));
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if n_intervals == 1
            R = C(r_idx);
        else
            R(:,interval_count) = C(r_idx);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if ismember('plot', option)
            clf
            subplot(2,2,1)
            imagesc(C)
            title(num2str(interval_count))
            subplot(2,2,2)
            plot(mean(Z_scores(EEG(start_idx:end_idx,:))'))
            axis tight
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            subplot(2,2,3:4)
            plot(Z_scores(EEG(start_idx:end_idx,:)) + repmat([1:size(EEG(start_idx:end_idx,:),2)]*4,size(EEG(start_idx:end_idx,:),1),1))
            hold on
            plot(mean(Z_scores(EEG(start_idx:end_idx,:)),2),'k-','LineWidth',2)
            axis tight
            title(num2str(interval_count))
            drawnow
        end
    end    
end
