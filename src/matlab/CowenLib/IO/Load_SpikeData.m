function [SD, SD_Merged] = Load_SpikeData(tfile_dir, quality_threshold, tfile_prefix, tfile_postfix, start_and_end_ts);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Loads in the spike info and spike times for warp tfiles of the format stuffSE_A3_3.t
% INPUT: Pass in the directory that contains the tfiles. 
%           The default tfiles.txt file will be loaded
%        The quality threshold (1 worst, 5 best) - IF USER PASSES IN A CELL
%        ID INSTEAD OF QUALITY THRESHOLD, THEN IT ONLY RETURNS THOSE CELLS!
%        tfile_prefix is any file naming prefix that occurs in front of the 'SE'
%        tfile_postfix is any file naming postfix that occurs after the electrode ID.
%
% OUTPUT: SD A structure containing info about each cell and the spike times (T).
%         SDMerged Same as above, however, all clusters from the same channel are merged.
%            useful if you are worried about overlap between clusters or if your experiment
%            was based on information gathered from the channel and not the cluster.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    textread(fullfile(tfile_dir,'tfiles.txt'),'%s%d%f','commentstyle','matlab','delimiter',',');
% Get rid of the spaces in the channel field.
for ii = 1:length(TInfo.Ch)
    TInfo.Ch{ii} = strtok(TInfo.Ch{ii});
    ch(ii) = Alpha2Channel(TInfo.Ch{ii});
end
% Sort by channel and cluster number at this point - makes order consistent
% across datasets regardless of arbitrary tfile.txt organization.
[s, ix] = sortrows([ch(:) TInfo.Cluster(:)]);

TInfo.Ch = TInfo.Ch(ix);
TInfo.Cluster = TInfo.Cluster(ix);
TInfo.Quality = TInfo.Quality(ix);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the universal Cell ID for each cell.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[p,n,e] = fileparts(tfile_dir);
[p,ses_name,e] = fileparts(p);

SD.start_ts = inf;
SD.end_ts = 0;
count = 1;
SD.units = '.1msec';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a filename list given the information in the tfiles.txt file.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SD.tfile_name{1} = [];
prevCID = inf;
for ii = 1:length(TInfo.Ch)
    % Try to load in the cluster summary information for this tetrode if it
    % exists.
    tfile_name =  [ tfile_prefix TInfo.Ch{ii} '_' num2str(TInfo.Cluster(ii)) '.t'];
    CID = CID_from_filenames(ses_name,{tfile_name});
    if length(CID) > 1 | prevCID == CID
        error('more CIDs returned than requested or duplicates')
    end
    prevCID = CID;
    
    if CID < 10000
        error('Incorrect ID observed')
    end
    if TInfo.Quality(ii) >= quality_threshold(1) | (ismember(CID,quality_threshold))
        SD.tfile_path{count} =  tfile_dir;
        SD.tfile_name{count} = [ tfile_prefix TInfo.Ch{ii} '_' num2str(TInfo.Cluster(ii)) '.t'];
        if (count > 1) & strcmp(SD.tfile_name{count-1}, SD.tfile_name{count})
            error(['Duplicate tfile in !' pwd ' ' SD.tfile_name{count} ] )
        end
        SD.full_tfile_path_name{count} = fullfile(SD.tfile_path{count},SD.tfile_name{count});
        SD.electrode_string{count} = TInfo.Ch{ii} ;
        SD.cluster_number(count) = TInfo.Cluster(ii);
        SD.channel(count)     = Alpha2Channel(SD.electrode_string{count});
        SD.cell_string{count} = [SD.electrode_string{count} '_Ch' num2str(SD.channel(count)) '_' num2str(SD.cluster_number(count)) ];
        SD.cluster_quality(count) = TInfo.Quality(ii);
        SD.T{count}           = Load_tfiles(fullfile(tfile_dir,SD.tfile_name{count}));
        try
            cfile = [ tfile_prefix TInfo.Ch{ii} '_ClusterSummary_' num2str(TInfo.Cluster(ii)) '.mat'];
            SD.ClusterInfo{count} = load(fullfile(tfile_dir,cfile));
            if (length(SD.T{count}) ~= SD.ClusterInfo{count}.CI.nSpikes)
                disp(['WARNING: ' SD.full_tfile_path_name{count} '> ' num2str(length(SD.T{count})) ' in t file and ' num2str(SD.ClusterInfo{count}.CI.nSpikes) ' in ClusterSUMMARY file!!!!']);
            end
        catch
             SD.ClusterInfo{count}  =[];
             %disp(['Could not load the cluster summary information for '  SD.tfile_name{count}])
        end
        if ~isempty(start_and_end_ts)
            SD.T{count} = Restrict(SD.T{count},start_and_end_ts(:,1), start_and_end_ts(:,2));
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Check for duplicate timestamps. If you find them, warn the user and get rid of them.
        % unique also resorts the timestamps.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do another check to be sure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if Rows(unique([SD.channel(:) SD.cluster_number(:)],'rows')) ~= Rows([SD.channel(:) SD.cluster_number(:)] )
    pwd
    error('Duplicate tfiles')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate the universal Cell ID for each cell.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SD.CID = CID_from_filenames(ses_name,SD.tfile_name);

if nargout == 2
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
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % now elimiate the structures that have no spikes.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
