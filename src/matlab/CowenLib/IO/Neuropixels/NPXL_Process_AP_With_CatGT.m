function [out_fname, in_fname, status,cmdout] = NPXL_Process_AP_With_CatGT(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Be sure to ID bad channels before calling.
% EXAMPLE CALL: 
% NPXL_Extract_Events_With_CatGT('PRM_ROOT_DATA_DIR','C:\Data\DANA_NAc_Acute\Rat411\1112022_DANA_REAL_g0','PRM_EVENT_CHANNELS',[0 2 3])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2022
PRM_ROOT_DATA_DIR = pwd; % assume you are running in the current directory. This directory should end in _g0.
% for example: F:\Data\DANA_NAc_Acute\Rat411\1112022_DANA_REAL_g0
PRM_CATGT_DIR = 'C:\CatGT-win';
PRM_CATGT_PARAMS =  '-g=0 -t=0 -prb_fld -t_miss_ok -ni -ap -prb=0 -gblcar -xd=0,0,384,6,500'; % just extract the ni data
PRM_BAD_CHANNEL0_LIST = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Extract_varargin; % overrides the defaults specified above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
chn_cmd = [];
if ~isempty(PRM_BAD_CHANNEL0_LIST)
    lst = sprintf('%d,', PRM_BAD_CHANNEL0_LIST);
    lst(end) = [];
    chn_cmd = sprintf(' -chnexcl={0;%s} ', lst');
end
cmd = [PRM_CATGT_PARAMS chn_cmd];

% Construct the bad channel command and attach it to the main command
[top_folder,root_folder] = fileparts(PRM_ROOT_DATA_DIR);
DATA_DIR = fullfile(PRM_ROOT_DATA_DIR, [root_folder '_imec0']);
[~, specific_dir] = fileparts(DATA_DIR);
ix = strfind(specific_dir,'_g');
run_name = specific_dir(1:ix-1);
full_cmd = sprintf('%s/CatGT.exe -dir=%s -run=%s %s',PRM_CATGT_DIR, top_folder, run_name, cmd);

[status,cmdout] = system(full_cmd,'-echo');

d = dir(fullfile(DATA_DIR,'*tcat.*.ap.bin'));

if isempty(d)
    error('could not find tcat file.')
end
out_fname = fullfile(DATA_DIR,d(1).name);
% 
d = dir(fullfile(DATA_DIR,'*0.imec0.ap.bin'));
if isempty(d)
    error('could not find orig bin file.')
end
in_fname = fullfile(DATA_DIR,d(1).name);

