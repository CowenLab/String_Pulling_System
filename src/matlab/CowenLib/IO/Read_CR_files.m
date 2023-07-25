function [T, EEG, argout_1, argout_2] = Read_CR_files(eeg_files, sFreq, intervals_usec, option, option_parameters);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Reads in the EEG files specified and also re-refernces if desired.
%  Reading in at a lower sampling rate is performed by using a moving
%  average filter. This is done in the MEX file. This .m file subsequently
%  filters the data.
%
% INPUT:
%  eeg_files: cell array of eeg files (e.g. {'CSC1.ncs' 'CSC2.ncs'}
%  sFreq: desired sampling frequency Hz
%  intervals_usec: the intervals in usec of the period to load (n x 2 matrix)
%  option: optional filtering/transformation of the data. (cell array of
%  length nOptions)
%     'pca': return the principal component transform of the data
%     'bandpass': Perform a bandpass filter.
%     '60Hz': Remove 60Hz AND its harmonics from the data.
%     'reref_global_median': rereference the data using the global median -
%     and subtract the global median from each channel.
%  option_parameters is a cell array that contains the parameters required
%  by each option. (cell array of length nOptions)
%
% OUTPUT:
%  T: Timestamps for each datapoint (row) in EEG.
%  EEG: ntimestamps x nChannels matrix with EEG in uVolts
%
%  argout_1: depends on the options. for instance, if the principal
%  components are returned, then this becomes the matrix of eigenvectors
%  and argout_2 becomes the eigenvalues. If the data is rereferenced, then
%  this is the list of channel pairs that were used for re-referencing.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% options are specified in a non-conventional way (2 cell arrays where the first is the
%   name of the operation to perform and the second is the paramter associated with the operation.
%
%   e.g Read_CR_files({'A1.nsc' 'B4.nsc' }, 1000, [200202 404004400], {'bandpass' '60Hz' 'reref_global_median'},{[20 90] [] [})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Available Options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reref_nearest_regress:
% Rereference each electrode to its nearest neighbor and returns the output.
% Requires the x, y, and z location of each channel so a nchannels x 3 matrix
% in the option_parameters file.
%  COWEN 2005
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
argout_1 = [];
argout_2 = []; % I was having issues with varargout.
if isstr(eeg_files)
    tmp = eeg_files;
    clear eeg_files;
    eeg_files{1} = tmp;
end
if isempty(sFreq)
    error('The user must specify a desired sampling frequency.')
end

filter_order = 7; %arbitrary
reference_pairs = [];
if nargin < 4
    option = [];
    option_parameters = [];
end

if nargin < 3
    intervals_usec = [];
end
% At the time of this writing, Read_nlx_CR_files resamples by just taking the weighted average
% of the nearest 3 pts to the target timestamp. This is fine in most cases, but it does
% not get rid of high fq components for low fq data. This should be fixed
% in future versions.
if isempty(intervals_usec)
    [startts, endts, c, d] = ReadCR_get_info(eeg_files{1});
    % Restrict to just those times that are contained in the data.
    intervals_usec = [startts*100+1000 endts*100-1000];
%    intervals_usec = intervals_usec(find(intervals_usec(:,1) >= startts*100),:);
%    intervals_usec = intervals_usec(find(intervals_usec(:,2) <= endts*100),:);
%    intervals_usec = sortrows(intervals_usec);
end
% Convert the intervals to timestamps. This assumes that they are
% not overlapping. If a single vector was passed in, assume that there
% were no intervals
% It may be archived as a zip file.


T = binned(intervals_usec,1e6/sFreq);
T = unique(T(:,1));
if length(T) ~= length(unique(T))
    error('Assumes intervals are non-overlapping')
end

% Check all of the files to make sure that they exist and are unzipped.
for iF = 1:length(eeg_files)
    if ~exist(eeg_files{iF})
        [p,n,e] = fileparts(eeg_files{iF});
        zipfile = fullfile(p,[n '.zip']);
        if exist(zipfile)
            disp(['Unzipping ' zipfile ' to ' eeg_files{iF}])
            unzip(zipfile,p);
            % Check to be sure that the unzipped file exists
            d = dir(eeg_files{iF});
            if d(1).bytes > 10000
                % if it exists, delete the zipfile.
                delete(zipfile)
            else
                error(['Unable to Unzip ' eeg_files{iF}])
            end
        else
            error(['Could not find ' eeg_files{iF}])
        end
    end
end
[p,n,e] = fileparts(eeg_files{1});

% Load the data!
EEG = Read_nlx_CR_files(eeg_files, T);
% Load the header if possible and convert values to uVolts.
for ii = 1:length(eeg_files)
    try
        H = Read_nlx_header(eeg_files{ii});
        EEG(:,ii) = EEG(:,ii)*(H.ADBitVolts*1e6); % convert to uVolts
        %disp('Units in uVolts')
    catch
        disp('Could not read uVolts so units are in bits')
    end
end

%disp(['Loaded the data in ' num2str(toc) ' seconds.'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isstr(option)
    option = {option};
end
for op_cnt = 1:length(option)
    switch lower(option{op_cnt})
        case 'reref_global_median'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Subtract off the median of all channels from the target channel
            %  THIS IS THE CURRENT STANDARD RE-REFERENCING PROCEDURE.
            %  IT QUITE EFFECTIVELY GETS RID OF COMMON SIGNAL.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % First subtract the median from each channel to correct for any DC offset.
            for ii = 1:Cols(EEG)
                EEG(:,ii) = EEG(:,ii) - median(EEG(:,ii));
            end
            if isempty(option_parameters{op_cnt})
                % Next, Create a matrix of median activity from all but the target electrode.
                ref_eeg = zeros(size(EEG));
                for ii = 1:Cols(EEG)
                    all_but = setdiff(1:Cols(EEG),ii);
                    ref_eeg(:,ii) = median(EEG(:,all_but)')';
                end
                EEG = EEG - ref_eeg;

            else
                % The user passed in a list of files that will form the median
                % reference.
                % Load in the reference files...
                [T, ref_eeg] = Read_nlx_CR_files(option_parameters{op_cnt}, sFreq, intervals_usec);
                for ii = 1:Cols(ref_eeg)
                    ref_eeg(:,ii) = ref_eeg(:,ii) - median(ref_eeg(:,ii));
                end
                ref_eeg = median(ref_eeg')';
                EEG = EEG - repmat(ref_eeg,1,Cols(EEG));
            end
            clear ref_eeg;
            pack
        case 'reref_nearest_regression'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Rereference each electrode to its nearest neighbor and returns the output.
            % Requires the x, y, and z location of each channel so a nchannels x 3 matrix
            % in the option_parameters file.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            Dist = pdist(option_parameters{op_cnt},'euclid');
            Dist = squareform(Dist); % Makes it easier to understand.
            Dist(find(Dist == 0)) = inf; % Ignore the diagonals.
            partner = [];
            %error(1)

            for dd =1:size(Dist,1)
                dst = Dist(dd,:);
                [mn, tmp_idx] = min(dst);
                dst(tmp_idx) = inf;
                [mn, tmp_idx2] = min(dst);
                partner{dd} = [tmp_idx(1) tmp_idx2(1)];
                tmp(dd) = tmp_idx(1);
                tmp2(dd) = tmp_idx2(1);
            end
            reference_pairs = [1:size(Dist,1); tmp; tmp2]';
            argout_1 = reference_pairs;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Decorrelate with a window of about 10 seconds to denoise the system.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [EEG,S] = Decorrelate_Matrix(EEG, partner, sFreq*10);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Do the decorrelation by intervals. THis is teh way to go to
            % get rid of non-stationarities.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %interval_duration_sec = 30;
            % Given the non-stationarity of the data, this is the way to go.
            % It is more difficult.
        case 'ica'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Perform ICA on the data and return these decorrelated data.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'pca'
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Perform PCA on the data and return these decorrelated data.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            [argout_1, EEG, argout_2] = princomp(EEG);
            % argout_1 = PC matrix
            % argout_2 = Latent

        case 'reref_subtraction'
            Dist = pdist(option_parameters{op_cnt},'euclid');
            Dist = squareform(Dist); % Makes it easier to understand.
            Dist(find(Dist == 0)) = inf; % Ignore the diagonals.
            partner = [];
            %error(1)

            for dd =1:size(Dist,1)
                [mn, tmp_idx] = min(Dist(dd,:));
                partner{dd} = tmp_idx(1);
                tmp(dd) = tmp_idx(1);
            end
            reference_pairs = [1:size(Dist,1); tmp]';
            zEEG = Z_scores(EEG);
            for cc = 1:size(EEG,2)
                EEG(:,cc) = zEEG(:,cc) - zEEG(:,partner{dd});
            end
        case 'filter_out_60hz'
            % Filter out the 60Hz and the harmonics.
            if(0)
                for ii =1:length(eeg_files)
                    [F,Fconf,xF] = psd(EEG(:,ii),sFreq,sFreq,sFreq);
                    figure
                    semilogy(xF,F);
                    plot(xF,F);
                    hold on;
                    plot(xF,Fconf(:,1),'r:');
                    plot(xF,Fconf(:,2),'r:');
                    axis tight
                    title(eeg_files{ii})
                end
            end

            if sFreq > 60
                [b,a] = butter(5, [58 62]/(sFreq/2),'stop');
                EEG = filtfilt(b,a,EEG);
            elseif sFreq >120
                [b,a] = butter(5, [118 122]/(sFreq/2),'stop');
                EEG = filtfilt(b,a,EEG);
            elseif sFreq > 180
                [b,a] = butter(5, [178 182]/(sFreq/2),'stop');
                EEG = filtfilt(b,a,EEG);
            elseif sFreq > 240
                [b,a] = butter(5, [238 242]/(sFreq/2),'stop');
                EEG = filtfilt(b,a,EEG);
            end
        case {'hipass' 'highpass'}
            Cutoff_fq_Nq = option_parameters{op_cnt}/(sFreq/2);
            [b,a] = butter(filter_order, Cutoff_fq_Nq,'high');
            EEG2 = filtfilt(b,a,EEG);
            % RESAMPLE
            %Fs = round(Fs);
            %EEG = resample(EEG,filter_cutoff_Hz*2.4,Fs);
            %Fs = filter_cutoff_Hz*2.4;

        case 'emg_envelope'
            % Returns EMG data filtered and smoothed to best indicate EMG
            % changes. Find peaks and then smooth. 
            if sFreq < 1999
                error('EMG should be sampled at 2000Hz or more')
            end
            [b,a] = butter(6, [105 905]/(sFreq/2));
            EEG = filtfilt(b,a,EEG);
            PeaksIdx  = find([diff(EEG); 0] < 0 & [0; diff(EEG)] > 0);
            %T0x = T0(PeaksIdx);
            % smooth baby smooth.
            EEG =sgolayfilt(EEG(PeaksIdx),2,201); % assign a 2d polynomial to about 100msec of data.
            T = T(PeaksIdx);
        case 'spike_envelope'
            % Returns data filtered and smoothed to best indicate high frequency activity that
            % should correspond to MUA. SMooth it as well to produce an
            % envelope.
            
            % ABORT ABORT - this will take some more work. DO NOT DO NOW
            if sFreq < 1999
                error('EEG should be sampled at 2000Hz or more')
            end
            [b,a] = butter(6, [605 905]/(sFreq/2));
            EEG = filtfilt(b,a,EEG);
            for ii = 1:Cols(EEG)
                PeaksIdx  = find([diff(EEG(:,ii)); 0] < 0 & [0; diff(EEG(:,1))] > 0);
                %T0x = T0(PeaksIdx);
                % smooth baby smooth.
                EEG2(:,ii) =sgolayfilt(EEG(PeaksIdx,ii),2,101); % assign a 2d polynomial to about 50msec of data.
            end
            T = T(PeaksIdx);
        case 'bandpass'
            % Tried the following heuristic - no worko.(from eegfilt) filtorder = 3*fix(sFreq/min(option_parameters{op_cnt}));
            %EEG = eegfilt(EEG, sFreq, option_parameters{op_cnt}(1), option_parameters{op_cnt}(2));
            [b,a] = butter(6, option_parameters{op_cnt}/(sFreq/2));
            EEG = filtfilt(b,a,EEG);
            % RESAMPLE
            %Fs  = round(Fs);
            %newFs = round(max(filter_cutoff_Hz)*2.7);
            %EEG = resample(EEG,newFs,Fs);
            %Fs  = newFs;
        case 'lowpass'
            Cutoff_fq_Nq = option_parameters{op_cnt}/(sFreq/2);
            [b,a] = butter(filter_order,Cutoff_fq_Nq);
            EEG = filtfilt(b,a,EEG);
            % RESAMPLE
            %Fs = round(Fs);
            %EEG = resample(EEG,option_params*2.4,Fs);
            %Fs = filter_cutoff_Hz*2.4;
        case 'plot'
            if(0)
                for ii =1:length(eeg_files)
                    [F,Fconf,xF] = psd(EEG(:,ii),sFreq,sFreq,sFreq);
                    figure
                    semilogy(xF,F);
                    %plot(xF,F);
                    hold on;
                    plot(xF,Fconf(:,1),'r:');
                    plot(xF,Fconf(:,2),'r:');
                    axis tight
                    title(eeg_files{ii})
                end
            end
        case {'none' 'merged' []}
            % do nothing
        otherwise
            error(['BAD PARAMETER TYPE SWITCH: ' option{op_cnt}])
    end
end

