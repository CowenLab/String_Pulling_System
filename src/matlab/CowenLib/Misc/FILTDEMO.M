% Demonstration EEG filtering and visualization routines
%
% cowen Thu Jun 17 14:15:51 1999

% Load in two EEG files: a sleep EEG file and a maze running file.

dsn = 31;           % Data set number(dsn): 6568_04
S   = Session_info; % Load in all the rat data.

EEGfile    = fullfile(S(dsn).data_dir, 'CR1s2_f'); 
EEGfile_m1 = fullfile(S(dsn).data_dir, 'CR0m1_f');

% Change it to a tsd
disp(['Loading sleep EEG data from ' EEGfile]);
% ReadCR loads the data. CR_to_tsd converts the block structure of the
% output of ReadCR into a more manageable format(a tsd object: type
% help tsd for details)
crtsd = CR_to_tsd(ReadCR(EEGfile));
disp('Loading maze running EEG data');
crtsd_m1 = CR_to_tsd(ReadCR(EEGfile_m1));
% Remember, this is blocked data so it must be interpolated if one is going to filter it.
% If you don't, you may get aberrant frequency components in the data.


stime = StartTime(crtsd); % Get the start time for the sleep data
etime = EndTime(crtsd);   % Get the end time for the sleep data
stime_m1 = StartTime(crtsd_m1); % Get the start time for the maze data
etime_m1 = EndTime(crtsd_m1);   % Get the start time for the maze data

stime = 50009153 % I looked through the data and decided this was a good location(lots of ripples)

% Take out a small interval from the maze or sleep cr file
small_crtsd = Restrict(crtsd,stime - 20000, stime + 200000 ); 
small_crtsd_m1 = Restrict(crtsd_m1,stime_m1 - 20000, stime_m1 + 200000 ); 


figure
disp('200 Hz Demo')
% Filter the data around 200 Hz
R = Filter_200hz(small_crtsd,100,300);
% Find the start and end times of all the ripples. the second
% parameter is the threshold for selecting a ripple. The final
% parameter instructs Ripple_times to plot the data.
[st_ts, et_ts, all_ts] = Ripple_times(R,40);
L{1} = R;      % Filtered data
L{2} = st_ts;  % start time
L{3} = et_ts;  % end time
L{4} = all_ts, % all superthreshold points
L{5} = tsd(Range(small_crtsd,'ts'),Data(small_crtsd)*.3); % Scaled down actual data
View_EEG(L,1,300,110)  % View the data with a time window of 1 second and a y axis of +- 200.

close

figure;
disp('Theta Demo')

T{1} = Filter_7hz(small_crtsd_m1,6,10); % FIlter around 7Hz 
T{2} = small_crtsd_m1; % The actual maze data
View_EEG(T,1,1000);    % View the EEG data
close