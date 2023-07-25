function [status,cmdout] = NPXL_Sync_With_TPrime_SS(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% For tprime: http://billkarsh.github.io/SpikeGLX/help/syncEdges/Sync_edges/
% EXAMPLE CALL:
% NPXL_Extract_Events_With_CatGT('PRM_ROOT_DATA_DIR','C:\Data\DANA_NAc_Acute\Rat411\1112022_DANA_REAL_g0','PRM_EVENT_CHANNELS',[0 2 3])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
PRM_ROOT_DATA_DIR = pwd; % assume you are running in the current directory. This directory should end in _g0.
% for example: F:\Data\DANA_NAc_Acute\Rat411\1112022_DANA_REAL_g0
PRM_TPRIME_DIR = 'C:\TPrime-win';
PRM_AlignSpikes=false; %This will run a check on spikes after kilosort/phy
EVT_Channels=[];
EVT_Channel_Names=[];

Extract_varargin; % overrides the defaults specified above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[top_folder,root_folder] = fileparts(PRM_ROOT_DATA_DIR);
DATA_DIR = fullfile(PRM_ROOT_DATA_DIR, [root_folder '_imec0']);

%
% set LOCALARGS=-syncperiod=1.0 ^
% -tostream=Y:\tptest\time_trans_01_g0_tcat.imec0.ap.SY_301_6_500.txt ^
% -fromstream=7,Y:\tptest\time_trans_01_g0_tcat.nidq.XA_0_500.txt ^
% -events=7,Y:\tptest\time_trans_01_g0_tcat.nidq.XA_1_7700.txt,Y:\tptest\out.txt
% 1112022_DANA_REAL_g0_tcat.nidq.xa_0_500.txt

evt_files = dir(fullfile(PRM_ROOT_DATA_DIR,'*nidq.x*_0.txt'));

d = dir(fullfile(PRM_ROOT_DATA_DIR,'*_tcat.nidq.xa_0_500.txt'));
ni_sync_file = fullfile(PRM_ROOT_DATA_DIR,d(1).name);
d = dir(fullfile(DATA_DIR,'*ap.xd_384_6_500.txt'));
ap_sync_file = fullfile(fullfile(DATA_DIR,d(1).name)); %THis is the same file for all imec data (ap and lf)
% see http://billkarsh.github.io/SpikeGLX/help/syncEdges/Sync_edges/
% > TPrime -syncperiod=1.0 ^
%  -tostream=D:/CGT_OUT/catgt_demo_g0/demo_g0_imec0/demo_g0_tcat.imec0.ap.xd_100_6_500.txt ^
%  -fromstream=1,D:/CGT_OUT/catgt_demo_g0/demo_g0_imec1/demo_g0_tcat.imec1.ap.xd_384_6_500.txt ^
%  -fromstream=2,D:/CGT_OUT/catgt_demo_g0/demo_g0_tcat.nidq.xd_1_3_500.txt ^
%  -events=1,D:/CGT_OUT/catgt_demo_g0/demo_g0_imec1/spike_seconds.npy,D:/CGT_OUT/catgt_demo_g0/demo_g0_imec1/spike_seconds_adj.npy ^
%  -events=2,D:/CGT_OUT/catgt_demo_g0/demo_g0_tcat.nidq.xa_0_25.txt,D:/CGT_OUT/catgt_demo_g0/go_cue.txt ^
%  -events=2,D:/CGT_OUT/catgt_demo_g0/demo_g0_tcat.nidq.xd_1_2_0.txt,D:/CGT_OUT/catgt_demo_g0/nose_poke.txt
%

tostream_file = ap_sync_file; % to (often the -xb from the .ap file. -The reference stream we will map to. It is defined by a file of sync wave edges as extracted by CatGT. There is only one of these.
fromstream_file = ni_sync_file; % from (often a .ni event) A native stream we will map from. There can be several of these. A fromstream is identified by a file of sync wave edges extracted by CatGT, and, an arbitrary positive integer that is a shorthand for that stream, just so you don't have to type the edge-file-path over and over.
% event_file = fullfile(PRM_ROOT_DATA_DIR,evt_files(1).name); % These are times you want to convert. Typically you will have a different file for every event class, such as all the spikes from probe zero, or all the nose_poke times from the NI stream. On the command line for each such file you will specify the stream index for the matching fromstream, an input file of native times, a new file path for the output time
% event_file_out = fullfile(PRM_ROOT_DATA_DIR,['synced_' evt_files(1).name]);
evt_str = [];
for iF = 1:length(evt_files)
    event_file = fullfile(PRM_ROOT_DATA_DIR,evt_files(iF).name); % These are times you want to convert. Typically you will have a different file for every event class, such as all the spikes from probe zero, or all the nose_poke times from the NI stream. On the command line for each such file you will specify the stream index for the matching fromstream, an input file of native times, a new file path for the output time
    event_file_out = fullfile(PRM_ROOT_DATA_DIR,['synced_' evt_files(iF).name]);
    evt_str = [evt_str sprintf('-events=5,%s,%s ',event_file, event_file_out)];
end

full_cmd = sprintf('%s/TPrime.exe -syncperiod=1.0 -tostream=%s -fromstream=5,%s %s',PRM_TPRIME_DIR, tostream_file, fromstream_file, evt_str);
[status,cmdout] = system(full_cmd,'-echo'); % I noteced that it was off about 200ms after 2 hrs in one dataset..
% Check for spike_times.npy in the .ap file. If it's there, create a new
% one as well.

if PRM_AlignSpikes
    spike_time_files = dir(fullfile(DATA_DIR,'spike_times.npy'));
    if ~isempty(spike_time_files)
        % load the meta and get the sampling rate.
        % Load the meta data...
        obj = SGLX_Class;
        d = dir(fullfile(DATA_DIR,'*.ap.meta'));
        meta = obj.ReadMeta(d(1).name,DATA_DIR);
        spike_sFreq = str2double(meta.imSampRate);
    end
    % for each of these files, convert them to the new times.
    for iF = 1:length(spike_time_files)
        % First, convert the file to a text file wiht TIMES. the studpid
        % spike_times.npy file is in record IDs.
        % Load the event records
        T = readNPY(fullfile(DATA_DIR,'spike_times.npy')); % these are not (*$()*! times - they are records. Geez.
        t_sec = double(T)/spike_sFreq;
        if any(diff(t_sec)<0)
            error('Timestamps are not in perfect ascending order. This should never happen.')
        end
        %     save(fullfile(DATA_DIR,'spike_seconds.mat'),'t_sec')
        writeNPY(t_sec,fullfile(DATA_DIR,'spike_seconds.npy')); % these are not (*$()*! times - they are records. Geez.
        %     te = readNPY(fullfile(DATA_DIR,'spike_seconds.npy')); % these are not (*$()*! times - they are records. Geez.

        % NOTE: In rare but regular occasions, the order of spikes will be switched
        % due to syncing - maybe 0.001% of the time. This violates a number of
        % assumptions and makes linking the timestamps to the original records
        % difficult. What is the solution?  I am not 100% sure.
        event_file = fullfile(DATA_DIR, 'spike_seconds.npy'); % These are times you want to convert. Typically you will have a different file for every event class, such as all the spikes from probe zero, or all the nose_poke times from the NI stream. On the command line for each such file you will specify the stream index for the matching fromstream, an input file of native times, a new file path for the output time
        event_file_out = strrep(event_file,'spike_seconds.npy','synced_spike_seconds.npy'); % These are times you want to convert. Typically you will have a different file for every event class, such as all the spikes from probe zero, or all the nose_poke times from the NI stream. On the command line for each such file you will specify the stream index for the matching fromstream, an input file of native times, a new file path for the output time
        full_cmd = sprintf('%s/TPrime.exe -syncperiod=1.0 -tostream=%s -fromstream=5,%s -events=5,%s,%s',PRM_TPRIME_DIR, tostream_file, fromstream_file, event_file, event_file_out);
        [status,cmdout] = system(full_cmd,'-echo');
        disp('be aware that synced_spike_seconds.npy may not be in perfect ascending order anymore due to syncing.')
    end
     % Save ONLY the experiment-relevant events in the Event.mat file.
    %Either you can create and event code csv or have input variables
    fname = fullfile(PRM_ROOT_DATA_DIR,'event_codes.csv');
    if exist(fname,'file')
        T = readtable(fname,'Delimiter',',');
    else
        if ~isempty(EVT_Channels)
            T=table(EVT_Channels,EVT_Channel_Names);
        else
            error('You must create a 3 col csv file called event_codes.csv that has in col 1 the event channel (1-7), the matlab-friendly variable name, and any notes. This goes in the top data folder (with the .nidq. file)')
        end
         
    end
    
    EVT = [];
    

    d = dir(fullfile(PRM_ROOT_DATA_DIR,'synced_*tcat.nidq.xa_*.txt'));
    for iD = 1:length(d)
        ix = strfind(d(iD).name,'.xa_');
        ch0 = str2double(d(iD).name(ix+4:ix+4));
        ix = find(T.Var1 == ch0);
        if isempty(ix)
            % skip
        else
            t = load(fullfile(PRM_ROOT_DATA_DIR,d(iD).name));
            EVT.(char(T.Var2(ix))).time_sec = t;
            EVT.(char(T.Var2(ix))).notes = char(T.Var3(ix));
        end
        %     EVT(iD).orig_times_sec = T;
    end
    % The time each pulse turns off.
    d = dir(fullfile(PRM_ROOT_DATA_DIR,'synced_*tcat.nidq.xia_*.txt'));
    for iD = 1:length(d)
        ix = strfind(d(iD).name,'.xia_');
        ch0 = str2double(d(iD).name(ix+5:ix+5));
        ix = find(T.Var1 == ch0);
        if isempty(ix)

        else
            t = load(fullfile(PRM_ROOT_DATA_DIR,d(iD).name));
            EVT.([char(T.Var2(ix)) '_off']).time_sec = t;
            EVT.([char(T.Var2(ix)) '_off']).notes = char(T.Var3(ix));
        end
        %     EVT(iD).orig_times_sec = T;
    end

    save(fullfile(PRM_ROOT_DATA_DIR,'Events.mat'),'EVT')
end

end



   
