function [Q_s1_ts, Q_m1_ts, Q_s2_ts] = Load_Qs_as_ts(data_dir, RIPPLES, dt)
% Yes, this is ugly, but it will do for now.
% INPUT:
%       All sorts of things.
%
% OUPUT: 
%       The three Q matrices.
s = filesep;

if strcmp(computer,'PCWIN')
   extension = 'pc'
else 
   extension = '';
end

% Calculate the real hh mm ss times from the timestamps.
%times_s1 = [Timestamp_to_hms(s1_timestamps(:,1)) Timestamp_to_hms(s1_timestamps(:,2))] ;
%times_m1 = [Timestamp_to_hms(m1_timestamps(:,1)) Timestamp_to_hms(m1_timestamps(:,2))] ;
%times_s2 = [Timestamp_to_hms(s2_timestamps(:,1)) Timestamp_to_hms(s2_timestamps(:,2))] ;


% Get the names of the tfiles
s1_data_set = [data_dir s 'raw_tfiles' s 'rawtfiles_sleep1' extension '.tfl'];
m1_data_set = [data_dir s 'raw_tfiles' s 'rawtfiles_maze1' extension '.tfl'];
s2_data_set = [data_dir s 'raw_tfiles' s 'rawtfiles_sleep2' extension '.tfl'];

% Load in the data as a ctsd object
Q_s1_ts = Load_Qts(s1_data_set, dt);
disp('loaded Q_S1');
Q_m1_ts = Load_Qts(m1_data_set, dt);
disp('loaded Q_M1');
Q_s2_ts = Load_Qts(s2_data_set, dt);
disp('loaded Q_S2');




