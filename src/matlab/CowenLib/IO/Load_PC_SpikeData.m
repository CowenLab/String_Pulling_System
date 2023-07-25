function [SD, SD_Merged] = Load_SpikeData(tfile_dir, quality_threshold, tfile_prefix, tfile_postfix, start_and_end_ts);
% Loads in the spike info and spike times for warp tfiles of the format stuffSE_A3_3.t
% INPUT: Pass in the directory that contains the tfiles. 
%           The default tfiles.txt file will be loaded
%        The quality threshold (1 worst, 5 best)
%        tfile_prefix is any file naming prefix that occurs in front of the 'SE'
%        tfile_postfix is any file naming postfix that occurs after the electrode ID.
%
% OUTPUT: SD A structure containing info about each cell and the spike times (T).
%         SDMerged Same as above, however, all clusters from the same channel are merged.
%            useful if you are worried about overlap between clusters or if your experiment
%            was based on information gathered from the channel and not the cluster.
% cowen
if nargin < 5
    start_and_end_ts = [];
end
if nargin < 4
    tfile_postfix = '';
end
if nargin < 3
    tfile_prefix = '';
end
if nargin < 2
    quality_threshold = 0;
end

SD = [];
SD_Merged = [];
if ~exist(tfile_dir)
    disp([tfile_dir ' Does not exist!'])
    return
end
[       TInfo.Ch,...
        TInfo.Cluster,...
        TInfo.Quality ] = ...
    textread(fullfile(tfile_dir,'tfiles.txt'),'%s%d%d','commentstyle','matlab','delimiter',',');
% Get rid of the spaces in the channel field.
for ii = 1:length(TInfo.Ch)
    TInfo.Ch{ii} = strtok(TInfo.Ch{ii});
end
SD.start_ts = inf;
SD.end_ts = 0;
count = 1;
SD.units = '.1msec';

% Create a filename list given the information in the tfiles.txt file.
for ii = 1:length(TInfo.Ch)
    if TInfo.Quality(ii) >= quality_threshold
        SD.tfile_path{count} =  tfile_dir;
        SD.tfile_name{count} = [ tfile_prefix TInfo.Ch{ii} '_' num2str(TInfo.Cluster(ii)) '.t'];
        SD.electrode_string{count} = TInfo.Ch{ii} ;
        SD.cluster_number(count) = TInfo.Cluster(ii);
        SD.channel(count)    = Alpha2Channel(SD.electrode_string{count});
        SD.cell_string{count}= [SD.electrode_string{count} '_Ch' num2str(SD.channel(count)) '_' num2str(SD.cluster_number(count)) ];
        SD.cluster_quality(count)= TInfo.Quality(ii);
        SD.T{count}          = load_tfiles(fullfile(tfile_dir,SD.tfile_name{count}));
        if ~isempty(start_and_end_ts)
            SD.T{count} = Restrict(SD.T{count},start_and_end_ts(1), start_and_end_ts(2));
        end
        
        % Check for duplicate timestamps. If you find them, warn the user and get rid of them.
        % unique also resorts the timestamps.
        l = length(SD.T{count});
        SD.T{count} = unique(SD.T{count});
        if l > length(SD.T{count})
            disp(['WARNING: Duplicate timestamps found in ' SD.cell_string{count} ])
        end
        
        if ~isempty( SD.T{count} )
            SD.start_ts         = min([SD.start_ts SD.T{count}(1)]);
            SD.end_ts           = max([SD.end_ts SD.T{count}(end)]);
        end
        count = count + 1;
    end
end

if nargout == 2
    d = diff([ 0 SD.channel]);
    idx = find(d == 0); % the ones to merge.
    tmp = SD;
    count = 1;
    for ii = 1:length(idx)
        nspikes_prev = length(tmp.T{idx(ii)-1});
        nspikes_curr = length(tmp.T{idx(ii)}); 
        tmp.T{idx(ii)} = unique([tmp.T{idx(ii)}; tmp.T{idx(ii)-1}] );
        tmp.T{idx(ii)-1} = [];
        tmp.cell_string{idx(ii)} = [tmp.cell_string{idx(ii)} '_merged'];
        nspikes_new = length(tmp.T{idx(ii)});
        disp([ SD.cell_string{idx(ii)} ': Prev cell ' num2str(nspikes_prev) ', Curr ' num2str(nspikes_curr) ', New ' num2str(nspikes_new) ', Overlap ' num2str(nspikes_curr+nspikes_prev - nspikes_new) ]);
    end
    % now elimiate the structures that have no spikes.
    count = 1;
    for ii = 1:length(tmp.channel)
        if ~isempty(tmp.T{ii})
            SD_Merged.tfile_path{count} = tmp.tfile_path{ii};
            SD_Merged.tfile_name{count} =  tmp.tfile_name{ii};
            SD_Merged.electrode_string{count} = tmp.electrode_string{ii};
            SD_Merged.cluster_number(count) = tmp.cluster_number(ii);
            SD_Merged.channel(count) = tmp.channel(ii);
            SD_Merged.cell_string{count}      = tmp.cell_string{ii} ;
            SD_Merged.T{count}   = tmp.T{ii};
            count = count + 1;
        end
    end
    SD_Merged.start_ts = SD.start_ts;
    SD_Merged.end_ts   = SD.end_ts;
end
