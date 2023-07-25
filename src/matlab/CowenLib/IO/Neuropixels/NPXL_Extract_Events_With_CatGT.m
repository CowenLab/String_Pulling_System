function [status,cmdout] = NPXL_Extract_Events_With_CatGT(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXAMPLE CALL: 
% NPXL_Extract_Events_With_CatGT('PRM_ROOT_DATA_DIR','C:\Data\DANA_NAc_Acute\Rat411\1112022_DANA_REAL_g0','PRM_EVENT_CHANNELS',[0 2 3])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
PRM_ROOT_DATA_DIR = pwd; % assume you are running in the current directory. This directory should end in _g0.
% for example: F:\Data\DANA_NAc_Acute\Rat411\1112022_DANA_REAL_g0
PRM_EVENT_CHANNELS = [1:7];% by default, get everything to avoid mistakes.
PRM_CatGT_dir = 'C:\CatGT-win';
% PRM_TPrime_dir = 'C:\TPrime-win';
% You need to -prb_fld so that it knows a separate folder contains each
% bin. That's how it's being saved now.
% Let's say that you would like the sync data from an .ap file. I do not
% know how to get ti beyond generating a duplicate .ap file - the docs say
% that it will only create a copy of the .bin if there is filtering or
% rereferencing. This is a slow waste of time.
PRM_CatGT_params_ni =  '-g=0 -t=0 -prb_fld -ni -prb=0 -inarow=3'; % just extract the ni data
% For tprime: http://billkarsh.github.io/SpikeGLX/help/syncEdges/Sync_edges/
Extract_varargin; % overrides the defaults specified above.
% Construct the bad channel command and attach it to the main command
chn_cmd = [];
for ii = 1:length(PRM_EVENT_CHANNELS)
    % first 2 inputs need to be 0 to specify stream type(ni) and extractor type
    % (ni)
    chn_cmd = [chn_cmd sprintf('-xa=0,0,%d,3.0,2.0,0 ', PRM_EVENT_CHANNELS(ii))];
    % Get the inverted pulse as well
    chn_cmd = [chn_cmd sprintf('-xia=0,0,%d,3.0,2.0,0 ', PRM_EVENT_CHANNELS(ii))];
    %      chn_cmd = [chn_cmd sprintf('-xd=0,0,%d,0,10 ', PRM_EVENT_CHANNELS(ii))];
end
% Add in the digital sync pulse too
chn_cmd = [chn_cmd ' -xd=0,0,384,6,500']; % this often has the sync pulse.
[top_folder,root_folder] = fileparts(PRM_ROOT_DATA_DIR);
DATA_DIR = fullfile(PRM_ROOT_DATA_DIR, [root_folder '_imec0']);
[~, specific_dir] = fileparts(DATA_DIR);
ix = strfind(specific_dir,'_g');
run_name = specific_dir(1:ix-1);
full_cmd = sprintf('%s/CatGT.exe -dir=%s -run=%s %s %s',PRM_CatGT_dir, top_folder, run_name, PRM_CatGT_params_ni, chn_cmd);
[status,cmdout] = system(full_cmd,'-echo');

