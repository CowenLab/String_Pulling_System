function Check_all_SE_files(wavefile_directory, t_file_directory, event_times,filetype)
% Checks all of the .t files in the current directory.
%function Check_all_SE_files(wavefile_directory, t_file_directory, event_times,filetype)
%
% INPUT (optional):
%    directory of the waveform files
%    directory of the tfiles. If this is a cell array of full tfile names and paths, then these
%     will be plotted. Leave empty of you don't want to plot tfile info (just raw waveform data).
%    event_times : timestamps of any event-- used for the generation of a PETH
%    filetype    : produce the summary plot for 't' files ('t') or raw .dat (.nse,.ntt etc..)
%                  files ('raw')
% OUTPUT: the plot.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 1 | nargin == 3
    filetype = 't'
end

if nargin == 0
    event_times = [];
end
features_to_show = {'energy', 'peak','SpikeWidth','wavePC1','wavePC2'};
switch filetype
case {'t','tstxt'}
    if iscell(t_file_directory)
        source = t_file_directory;
    else
        %source    = findfiles(fullfile(t_file_directory,'*SE*.t'),'CheckSubdirs',0);
        
        if strcmp(filetype,'tstxt')
            source    = find_files(fullfile(t_file_directory,'*SE*.tstxt'));
        else
            source    = find_files(fullfile(t_file_directory,'*SE*.t'));
        end
    end
    
    for iF = 1:length(source)
        [p,n,e] = fileparts(source{iF});
        %start_idx = findstr(n,'SE') + 2;
        idx1 = findstr(n,'SE_');
        idx2 = findstr(n,'_');
        if length(idx2) > 1
            idx2 = idx2(2);
        else    
            idx2 = length(n)+1;
        end
        rootname = n(idx1:idx2-1);
        if length(dir(fullfile(wavefile_directory,[ rootname '.dat'])))>0
            ext = '.dat';
        else
            ext = '.nse';
        end
        if ~isempty(event_times)
            Check_SE_Channel(fullfile(wavefile_directory,[ rootname ext]),source{iF},'event_times',event_times,'before_ts',1000*1000,'after_ts',1000*1000,'binsize_ts',20*1000,'features_to_show',features_to_show,'saveit',1)
        else
            Check_SE_Channel(fullfile(wavefile_directory,[ rootname ext]),source{iF},'features_to_show',features_to_show,'saveit',1)
        end    
    end
case {'raw' 'nse' 'dat'}
    source   = find_files(fullfile(wavefile_directory,'*SE*.nse'));
    if isempty(source)
        source   = find_files(fullfile(wavefile_directory,'*SE*.dat'));
    end
    
    for iF = 1:length(source)
        [p,n,e] = fileparts(source{iF});
        if ~isempty(event_times)
            Check_SE_Channel(source{iF},[],'event_times',event_times,'before_ts',1000*1000,'after_ts',1000*1000,'binsize_ts',20*1000,'features_to_show',features_to_show,'saveit',1)
        else
            Check_SE_Channel(source{iF},[],'features_to_show',features_to_show,'saveit',1)
        end    
    end
    
otherwise
    error('wrong file type')
end
