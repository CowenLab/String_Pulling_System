function [r, in, cED, rVals, r_idx, Cohere, Power] = Partial_r_react_EEG(eeg_files,broad_intervals_usec,small_interval_duration_min, filter_type, filter_cutoff_Hz);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [r, in, cED, rVals, r_idx] = Partial_r_react_EEG(eeg_files,broad_intervals_usec,small_interval_duration_min);
% INPUT:
%   eeg_files = a cell array of eeg files.
%   broad_interval = the epoch such as s1, maze, s2. A nX2 matrix of start and end timestamps.
%   small_interval_duration_min = the size of the chunks within the broad_interval (you can't load the entire thing-- too big)
% OUTPUT:
% 
% Load in the EEG data for each R and make a big R matrix.
% Compute the avereage R before during and after behavior.
%  cowen 2003
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4
    filter_type = 'none';
end

if nargin <= 4
    filter_cutoff_Hz = 500; % The default cutoff frequency for filtering.
end
fq_cutoff_for_psd = 500;
filter_order = 10; % This looks fine for butterworth in sptool, at least for sfreq at 2461.
nfiles = length(eeg_files);
r_idx = find(triu(ones(nfiles,nfiles))==0); % Must be 0, else you get the diagonal as well as the off diag.
[r_row,r_col] = find(triu(ones(nfiles,nfiles))==0); % Must be 0, else you get the diagonal as well as the off diag.
n_rs = length(r_idx); % number of r values in each matrix.

% Break each epoch into sections.
nepochs = Rows(broad_intervals_usec)
for ep = 1:nepochs
    tm = broad_intervals_usec(ep,1):small_interval_duration_min*60*1e6:(broad_intervals_usec(ep,2)-small_interval_duration_min*60*1e6);
    if isempty(tm)
        in{ep} = broad_intervals_usec(ep,:);
    else
        in{ep} = [tm(:) tm(:) + small_interval_duration_min*60*1e6];
    end
end
for ii = 1:nfiles
end
%
R = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Go through each epoch and then accumulate the r values (we will compute reactivation later.)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
interval_durations_usec = zeros(nepochs,size(in{ep},1))
for ep = 1:nepochs
    Power{ep} = zeros(fq_cutoff_for_psd,nfiles); % Cutoff at this hz
    Cohere{ep} = zeros(length(r_row),257);
    rVals{ep} = zeros(size(in{ep},1),n_rs)*nan; % Rows = intervals, Cols = the r values.
    for interval_count = 1:size(in{ep},1)
        cED{ep} = []; % cED stores the EEG data for ALL FILES. Each column represents a file. The rows are the eeg data.
        cTD{ep} = []; % cTD stores the timestamps for ALL FILES. Each column represents a file. The rows are the timestamps.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Just load the timestamps and then find the timestamps that are
        % in common to all files. Just load those times (some files will not have complete records.)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        load_intrvl = in{ep}(interval_count,:)
        intrvl = [0 inf];
        [common_TS, sFreq] = Load_EEG_Block_Timestamps(eeg_files{1},load_intrvl);
        for fc = 2:nfiles
            [TimeStamps] = Load_EEG_Block_Timestamps(eeg_files{fc},load_intrvl);
            intrvl(1) = max([intrvl(1), TimeStamps(1)])
            intrvl(2) = min([intrvl(2), TimeStamps(end)])
        end 
        interval_durations_usec(ep, interval_count) = diff(intrvl);
        % 
        clear common_TS TimeStamps
        pack
        
        for fc = 1:nfiles
            ED = nlx2matCSC_Matrix(eeg_files{fc}, intrvl);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Sometimes, only a partial record will load, perhaps due to fix_Cr. How do we deal with this? %
            % First solution is to just scrap the files that don't meet the criterion
            %  This would remove a lot of valuable data. The second option is to just take
            %  the times that all sets have in common. This might involve loading them twice.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % To do this properly, we are going to need to make sure all of the timestamps are
            % identical across trials. There is no guarantee. So to be careful, we should probably
            % interpolate.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if size(ED,1) > 200000
                ED = ED(1:200000,:); % Just get the data. No timestamps.
                fprintf('S')
            else
            end
            fprintf('(ep %i: interval: %i, file: %i)',ep, interval_count, fc)
            cED{ep} = [cED{ep} ED(:,2)]; % concatenate the current data to the cED{} variable.
            cTD{ep} = [cTD{ep} ED(:,1)];
        end
        clear ED
        pack
        Fs = 1/mean(diff(cTD{ep}(:,1)))*1e6 % Sampling frequency
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Filter the data and then do the analysis.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        switch filter_type
        case 'hipass'   
            % Filter the data
            Cutoff_fq_Nq = filter_cutoff_Hz/(Fs/2);
            [b,a] = butter(filter_order,Cutoff_fq_Nq,'high');
            cED{ep} = filtfilt(b,a,cED{ep});
            % RESAMPLE
            cED{ep} = resample(cED{ep},Fs,filter_cutoff_Hz*2.4);
            Fs = filter_cutoff_Hz*2.4;
        case 'ripple'   
            % Filter the data
            [b,a] = butter(5, [90 250]/(Fs/2));
            cED{ep} = filtfilt(b,a,cED{ep});
            % RESAMPLE
            cED{ep} = resample(cED{ep},Fs,250*2.4);
            Fs = filter_cutoff_Hz*2.4;
        case 'lowpass'   
            % Filter the data
            Cutoff_fq_Nq = filter_cutoff_Hz/(Fs/2);
            [b,a] = butter(filter_order,Cutoff_fq_Nq);
            cED{ep} = filtfilt(b,a,cED{ep});
            % RESAMPLE
            cED{ep} = resample(cED{ep},Fs,filter_cutoff_Hz*2.4);
            Fs = filter_cutoff_Hz*2.4;
        case 'none'
            % do nothing
        otherwise
            error('BAD FILTER TYPE SWITCH')
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Coherence analysis
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for ii = 1:length(r_row)
            [Cxy, Fc] = cohere(cED{ep}(:,r_row(ii)),cED{ep}(:,r_col(ii)),512);
            %[CSDxy, Fcsd] = csd(cED{ep}(:,r_row(ii)),cED{ep}(:,r_col(ii)),sFreq,sFreq,sFreq);
            Cohere{ep}(ii,:) = Cohere{ep}(ii,:) + Cxy'/mean(Cxy);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Calcualte the corrcoef
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        C = corrcoef(cED{ep});
        rVals{ep}(interval_count,:) = C(r_idx);
    end
    fprintf('\n')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot the coherence results.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    u = unique(r_row);
    for ii = 1:length(u)
        idx = find(r_row==u(ii));
        figure
        for jj = 1:length(idx)
            subplot(length(idx),1,jj)
            plot(Fc*(Fs/2),Cohere{ep}(idx(jj),:));
            a = axis; axis tight; a2 = axis;
            axis([a2(1) a2(2) a(3) a(4)])
            set(gca,'FontSize',8)
            title(['EP ' num2str(ep) ' ' num2str(r_row(idx(jj))) ' vs ' num2str(r_col(idx(jj)))],'FontSize',8)
        end
    end
    figure;plot(Fc*(Fs/2),mean(Cohere{ep}));title(num2str(['Mean EP ' num2str(ep)])); axis tight 
    Fs = round(Fs);
    for ii = 1:nfiles
        pd = psd(cED{ep}(:,ii),Fs,Fs,Fs); % The window and sampling fq and nfft are teh same so each point is a hz.
        Power{ep}(:,ii) = Power{ep}(:,ii) + pd(1:fq_cutoff_for_psd);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Now we make the assumption that the mean is appropriate. I imagine it is
% but i never tested it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if size(rVals{1},1) > 1
    A = mean(rVals{1});
else
    A = rVals{1};
end
if size(rVals{2},1) > 1
    B = mean(rVals{2});
else
    B = rVals{2};
end
if size(rVals{3},1) > 1
    C = mean(rVals{3});
else
    C = rVals{3};
end

try
    r = Partial_r([A(:) B(:) C(:)]); % I is S1, M, S2 vector
catch
    disp('ERROR: FAILED PARTIAL R')
    r = nan;
end