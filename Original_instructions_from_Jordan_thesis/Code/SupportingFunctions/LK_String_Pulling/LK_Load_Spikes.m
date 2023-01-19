function [SP,TS] = LK_Load_Spikes(neuron_quality_threshold, intervals)
%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    intervals = [];
end
GP = LK_Globals;
SP = [];TS = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the spikes...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist(GP.fnames.spike_file,'file')
    load(GP.fnames.spike_file)
elseif exist(fullfile(LK_tfile_dir,GP.fnames.spike_file),'file')
    load(fullfile(LK_tfile_dir,GP.fnames.spike_file));
else
    pwd
    error('NO SPIKE FILES FOUND!')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the recording day
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%il
load(GP.fnames.meta_file)
[META.recdatestr] = LK_Determine_Recording_Time_From_Datadir;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the depths of each electrode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[DEPTHS] = LK_Load_Depths('..',META.recdatestr);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Eliminate crappy cells and restrict time if that is requested
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SPtmp = struct(SP);
SPtmp(2:end) = [];
cnt = 1;
for iS = 1:length(SP)
    if SP(iS).Quality >= neuron_quality_threshold
        SPtmp(cnt) = SP(iS);
        cnt = cnt + 1;
    end
end
SP = SPtmp;
if ~isempty(intervals)
    for iS = 1:length(SP)
        SP(iS).t_uS = Restrict(SP(iS).t_uS,intervals);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Determine the depth of each spike
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TS = cell(length(SP),1);
for iS = 1:length(SP)
    IX = DEPTHS(:,1) == SP(iS).Tetrode;
    SP(iS).Depth_uM = DEPTHS(IX,2);
    TS{iS} = SP(iS).t_uS;
end

LtT = readtable('../LFP_to_Tetrode.xlsx');
TT2d = readtable('../Tetrode_2d_Cordinates.xlsx');
d = dir('../*channel_translation*.xlsx');
% CTT = readtable(fullfile('..',d(1).name));


for iS = 1:length(SP)
    IX = LtT.Tetrode == SP(iS).Tetrode;
    SP(iS).Tetrode_Channels = nan;
    if any(IX)
        SP(iS).Tetrode_Channels = LtT.LFPChannel(IX);
    end
    
    IX = TT2d.Tetrode == SP(iS).Tetrode;
    SP(iS).Hemisphere = nan;
    SP(iS).APmm = nan;
    SP(iS).MLmm = nan;
    
    if any(IX)
        a = TT2d.Hemisphere(IX);
        SP(iS).Hemisphere = a{1};
        SP(iS).APmm = TT2d.APmm(IX);
        SP(iS).MLmm = TT2d.MLmm(IX);
    else
%         error('wtf')
    end
    
end
