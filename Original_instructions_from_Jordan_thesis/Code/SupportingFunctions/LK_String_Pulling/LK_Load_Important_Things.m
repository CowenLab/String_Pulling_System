function [GP,E,EVT,SP,RHD,META,DEPTHS,TS] = LK_Load_Important_Things(DATA_DIR)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the important files that go with just about any analysis...
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1
    DATA_DIR = pwd;
end
neuron_quality_threshold = 1;
PAW = [];
SP = [];
TS = [];
DEPTHS = [];
META = [];
EVT = [];
E = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
GP = LK_Globals;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the recording day
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('Meta_data.mat')
[META.recdatestr] = LK_Determine_Recording_Time_From_Datadir;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the depths of each electrode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[DEPTHS] = LK_Load_Depths('..',META.recdatestr);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load event times.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
etimes_file = find_files('Event_times*.xlsx');
if length(etimes_file) > 1
    error('more than one event times file')
end
if isempty(etimes_file)
    error('No Event_times.xlsx file')
else
    E = LK_Load_Events_From_Excel(etimes_file{1});
end
if isempty(E)
    disp('NO Event_times.xlsx file. ')
    %     LK_Create_Event_times_file();
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the spikes...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[SP,TS] = LK_Load_Spikes(2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the rhd file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RHD = INTAN_Read_RHD_file('info.rhd');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the Event Times data...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load('EVT.mat')
% Loading paw - now do this in
