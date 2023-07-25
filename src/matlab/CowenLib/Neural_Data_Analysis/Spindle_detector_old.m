function [start_end_times, P] = Spindle_detector(LFP,sFreq,sleep_intervals)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
thresh_uVolts = 8; % (Gais et al. 2002)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load in the entire record - subsample at 100Hz - should be more than
% enough.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
output_sFreq = 200;
F_Ny    = output_sFreq/2;           % Hz
N = 4;                    % Order of the filter
lowlimit = 17;
highlimit = 19;
H = Read_nlx_header(eeg_file);
start_end_times = [];
for ii = 1:size(intervals,1)
    [TIME_USEC, DATA, sFreq] = ReadCR_to_matrix(eeg_file,intervals(ii,1), intervals(ii,2), output_sFreq);
    % Convert the data to uVolts
    DATA = DATA*H.ADBitVolts*1e6;
    % Filter the data.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Filter parameters
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    lowcut  = lowlimit/F_Ny;   % Hz
    highcut = highlimit/F_Ny; % Hz
    passband = [lowcut highcut];
    ripple = .1;
    %[Bb,Ab] = butter(N, passband);
    [B,A] = cheby1(N, ripple, passband);
    Y = filtfilt(B,A,DATA);
    passband = [4/F_Ny 8/F_Ny];
    [B,A] = cheby1(N, ripple, passband);
    Y2 = filtfilt(B,A,DATA);
   % Y = (Y - Y2);
    %
    rmY = sqrt(Y.*Y);
    rmY2 = sqrt(Y2.*Y2);
    d = decimate(rmY,10);
    d_times = linspace(TIME_USEC(1),TIME_USEC(end),length(d));
    cross = diff([0 d] > thresh_uVolts);
    start_times = d_times(find(cross == 1));
    end_times = d_times(find(cross == -1));
    ls = length(start_times);
    le = length(end_times);
    if  ls > le
       start_times(end) = [];
    elseif le > ls
       end_times(end) = [];
    end
    
    SE_times = [start_times(:) end_times(:)];
   % dd = SE_times(2:end,1) - SE_times(1:(end-1),2);
   % mergers = find(dd < 0.3 * 1e6);
   % SE_times(mergers,2)   = SE_times(mergers+1,2);
   % SE_times(mergers+1,:) = [];
    
    durations_sec = (SE_times(:,2) - SE_times(:,1))/1e6;
    goodix = find(durations_sec > 0.5 ); %& durations_sec < 3.0);
    new_SE_times = SE_times(goodix,:);
   % new_new_SE_times = [];
   % dd = new_SE_times(2:end,1) - new_SE_times(1:(end-1),2);
   % mergers = find(dd < 0.4*1e6);
   % new_SE_times(mergers,2) = new_SE_times(mergers+1,2);
   % new_SE_times(mergers+1,:) = [];
    
    start_end_times = [start_end_times; new_SE_times];
      
    %diff_times = diff(d_times(ix));
    
    
    figure
    plot(TIME_USEC,Z_Scores(DATA))
    hold on
    plot(TIME_USEC,Z_Scores(Y)-4,'r')

    plot(TIME_USEC,Z_Scores(rmY)-8,'k:')
    plot(TIME_USEC,Z_Scores(rmY2)-17,'c')
    plot(d_times, Z_Scores(d)-12,'m')
    plot(SE_times(:,1),zeros(size(SE_times(:,1))),'g>')
    plot(SE_times(:,2),zeros(size(SE_times(:,2))),'r<')
 
    plot(new_SE_times(:,1),2*ones(size(new_SE_times(:,1))),'g>')
    plot(new_SE_times(:,2),2*ones(size(new_SE_times(:,2))),'r<')
disp('sadf')

end