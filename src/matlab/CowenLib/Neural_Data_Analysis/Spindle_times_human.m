function [start_end_times_ix_units]= Spindle_times_human(eeg_data_200hZ, thresh_uVolts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function start_end_times_ix_units = Spindle_times(eeg_data_200hZ,
%thresh_uVolts) FOR HUMAN DATA
% 
% return the start and end times for spindle events.
% INPUT: raw eegdata sampled at 200hz!! Must be sampled at this rate. 
%        optional threshold in uV
%
% OUTPUT: nx2 matrix of start and end times (in units of indices in the
% original input data)
%
% cowen
%TO ADD: A high frequency reject criterion - it does well, but hf artifact
%  creeps in. If we could detect those artifacts and then eliminate all
%  spindle times that overlap with the artifact, I believe we could do a lot
%  better.
%
% Gais 2002
%
% Spindles were counted by means of an automatic algorithm that used the following steps: 
% (1) filtering the EEG with a 12-15 Hz bandpass filter, 
% (2) calculating the root mean square (RMS) of each 100 msec interval of the filtered signal, 
% (3) counting the number of times the RMS power crossed a constant detection threshold of 10 µV for 0.5-3 sec. 
% 
% This algorithm correctly identified >95% of the spindles detected by visual scoring of 
% experienced raters. Also, individual differences in spindle power are negligible because 
% all statistical tests were within-subject comparisons. 
% (4) Spindle density was calculated as the mean number of spindles per 30 sec epoch. 
% Spindle detection was performed in Matlab. Because spindle activity in the human 
% EEG can be measured best on midline electrode positions, this report focuses on results 
% from frontocentral (Fz) and central (Cz) electrodes. Analysis of other electrode 
% positions did not add essentially to the interpretation of data. Statistics relied on a
% double-sided paired sample t test, with results of p <= 0.05 considered as significant.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    thresh_uVolts = [];
end
sFreq = 200; % presumed input sFreq.
artifact_thresh_uV = 120; % If the raw EEG trace goes above this, get rid of the signal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Make it a row vector if it isn't already.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eeg_data_200hZ = reshape(eeg_data_200hZ,1,length(eeg_data_200hZ));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Normalize to the mean.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eeg_data_200hZ = eeg_data_200hZ - mean(eeg_data_200hZ);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F_Ny    = sFreq/2;        % Hz
% HUMAN PARAMETERS:::::
lowlimit = 11; % 12 Gais - but young kids probably lower.
highlimit = 14; % 15 from Gais but this data looks more centered around 13
min_duration_sec = 0.5; % .5 (Gais et al. 2002)
if isempty(thresh_uVolts)
    thresh_uVolts = 10; % 10 (Gais et al. 2002)
end
% RAT   lowlimit = 17; highlimit = 19;  min_duration_sec = 0.3;

N = 4;                    % Order of the filter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter the data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lowcut   = lowlimit/F_Ny;     % Hz
% highcut  = highlimit/F_Ny;    % Hz
% passband = [lowcut highcut];
% %ripple   = .1;
% ripple   = .5;
% %[B,A]  = butter(N, passband);
% [B,A]    = cheby1(N, ripple, passband);
% Y        = filtfilt(B,A,eeg_data_200hZ);
[B,A]=fir1(48,[lowlimit/sFreq*2 highlimit/sFreq*2]);                 % set up the filter
Y = filtfilt(B,A,eeg_data_200hZ);   % from  Daniel Fabó 2003 (about the
%same as my eeglab call.
% Y = eegfilt(eeg_data_200hZ,sFreq,lowlimit,highlimit); % it works the same as my filtering.
% Yhigh = eegfilt(eeg_data_200hZ,sFreq,30,0); % it works the same as my filtering.
[B,A]=fir1(48,[30/sFreq*2 50/sFreq*2]);                 % set up the filter
Yhigh = filtfilt(B,A,eeg_data_200hZ);   % from  Daniel Fabó 2003 (about the

% My non-linear filter works better than rms dammit.
Y = abs(Y);
Yhigh = abs(Yhigh);
smooth_data = Y;
for ii = 2:10
    smooth_data(ii:end) = max([Y(1:end-ii+1); smooth_data(ii:end)]);
end
% recenter (the smooth_data is shifted slightly to the right.
smooth_data(1:end-3) = smooth_data(4:end);

above_ix = find_intervals([[1:length(smooth_data)]' smooth_data(:)],thresh_uVolts);
SE_times_sec = above_ix./sFreq;

if 0 % got rid of this march 11 - added above.
    cross_points    = diff([0 smooth_data] > thresh_uVolts); % Apply the threshold
    start_times_ix_units  = find(cross_points == 1);
    end_times_ix_units    = find(cross_points == -1);
    ls = length(start_times_ix_units);
    le = length(end_times_ix_units);
    if  ls > le
        start_times_ix_units(end) = [];
    elseif le > ls
        end_times_ix_units(end) = [];
    end
    SE_times_sec = [start_times_ix_units(:) end_times_ix_units(:)]./sFreq;
end
% dd = SE_times(2:end,1) - SE_times(1:(end-1),2);
% mergers = find(dd < 0.3 * 1e6);
% SE_times(mergers,2)   = SE_times(mergers+1,2);
% SE_times(mergers+1,:) = [];
durations_sec = (SE_times_sec(:,2) - SE_times_sec(:,1));
goodix = (durations_sec > min_duration_sec); %& durations_sec < 3.0);
start_end_times_ix_units = fix(SE_times_sec(goodix,:)*sFreq);
% Get rid of the times that contain spikes in high frequency noise.
badevent = [];
for ii = 1:size(start_end_times_ix_units)
    if max(Yhigh(start_end_times_ix_units(ii,1):start_end_times_ix_units(ii,2))> thresh_uVolts) || max(abs(eeg_data_200hZ(start_end_times_ix_units(ii,1):start_end_times_ix_units(ii,2)))> artifact_thresh_uV)
        badevent = [badevent;ii];
    else
        % move the threshold out to about .6 of the detection threshold.
        ix = start_end_times_ix_units(ii,1);
        while (smooth_data(ix) > thresh_uVolts * .6 && ix > 0)
            ix = ix - 1;
        end
        start_end_times_ix_units(ii,1) = ix;
        ix = start_end_times_ix_units(ii,2);
        while (smooth_data(ix) > thresh_uVolts * .6 && ix < length(smooth_data))
            ix = ix + 1;
        end
        start_end_times_ix_units(ii,2) = ix;
        
    end
end
% disp(['removed ' num2str(length(badevent)) ' high frequency and high amplitude triggers'])
start_end_times_ix_units(badevent,:) = [];
start_end_times_ix_units = unique(start_end_times_ix_units,'rows');
% new_new_SE_times = [];
% dd = new_SE_times(2:end,1) - new_SE_times(1:(end-1),2);
% mergers = find(dd < 0.4*1e6);
% new_SE_times(mergers,2) = new_SE_times(mergers+1,2);
% new_SE_times(mergers+1,:) = [];

if (nargout == 0)
    eeg_event_viewer([eeg_data_200hZ(:) smooth_data(:) Y(:) Yhigh(:)],start_end_times_ix_units,400,400,1/200)
    %    TIME = single(1:length(eeg_data_200hZ));
    figure
    space_leftright = 400;
    count = 1;
    for iPage = 1:floor(size(start_end_times_ix_units,1)/8)
        clf
        for ii = 1:8
            subplot(4,2,ii)
            st = start_end_times_ix_units(count,1)-space_leftright;
            ed = start_end_times_ix_units(count,2)+space_leftright;
            
            plot(eeg_data_200hZ(st:ed))
            hold on
            plot(smooth_data(st:ed),'c','LineWidth',3)
            plot(Y(st:ed),'r','LineWidth',2)            
            plot(Yhigh(st:ed),'k','LineWidth',2)
            plot(space_leftright,thresh_uVolts,'k>')
            plot(ed-st-space_leftright,thresh_uVolts,'r<')
            axis tight
            set(gca,'XTickLabel',str2double(get(gca,('XTickLabel')))/200)
            count = count + 1;      
            if count > size(start_end_times_ix_units,1)
                count = 1;
            end
        end
        pause
    end
end