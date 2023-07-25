function Neuraview_event_viewer(ncs_files_or_tsd,event_times,event_labels);
%function Neuraview_event_viewer(ncs_files_or_tsd,event_times,event_labels);
% This is a quick wrapper around Neuraview to quickly view some eeg files.
% It will also open an event file if you pass it in.
% INPUTS:
% CELL ARRAYS: list of file names to load, OR PERFECTLY SPACED DATA AND
% TIMESTAMPS. 
% list of event times.
% list of labels for the times.
%
%  ASSUMES YOU HAVE NEURAVIEW INSTALLED.
% Cowen (2013).

% Find path for neuraview.
NEURAVIEW_PATH = [getenv('ProgramFiles') '\Neuralynx\Neuraview200\'];
TEMP_PATH = getenv('TEMP');
event_file = [];
file_list = [];

if ~exist(NEURAVIEW_PATH,'dir')
    error([NEURAVIEW_PATH ' does not exist. Do you have Neuraview installed?'])
end

% Create the file list string.
for ii = 1:length(ncs_files_or_tsd)
    if isnumeric(ncs_files_or_tsd{ii})
        fname = [TEMP_PATH '/tmpCSC' num2str(ii) '.Ncs'];
        % NOT IMPLEMENTED YET: This will convert to a temporary ncs file so
        % that this file can be viewed in neuraview.
        disp('converting: NOT IMPLEMENTED OR DEBUGGED YET')
        % save data as an ncs file.
        % cut to a multiple of 512.
        ix = 1:512:Rows(ncs_files_or_tsd{ii});
        % Cut off the last block to ensure no overlap.
        ix(end) = [];
        ncs_files_or_tsd{ii} = ncs_files_or_tsd{ii}(1:(ix(end) + 512),:);
        TimeStamps = ncs_files_or_tsd{ii}(ix,1);
        Samples = reshape(ncs_files_or_tsd{ii}(:,2),length(TimeStamps),512);
        ExtractMode = 1;
        NlxHeader = []; % Need something for this
        %
        ModeArray(1) = 1;
        xFieldSelection(1) = 1;
        xFieldSelection(2) = 0;
        xFieldSelection(3) = 0;
        xFieldSelection(4) = 0;
        xFieldSelection(5) = 1;
        xFieldSelection(6) = 1;
        
        Mat2NlxCSC(fname , 0,ExtractMode, ModeArray, length(ix), xFieldSelection, TimeStamps, Samples,NlxHeader);
        %
        %    or see [p,n,e] = fileparts(CSCfilename);
        % [TimeStamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples, NlxHeader] = Nlx2MatCSC(CSCfilename,1,1,1,1,1,1,start_ts,end_ts);
        % Mat2NlxCSC(fullfile(p,[n '_r' e]), TimeStamps, ChannelNumbers, SampleFrequencies, NumberValidSamples, Samples, length(TimeStamps));
        
        
        % Write to TEMP PATH.
        fname = []; % sets the fname to the tmp fname.
    else
        fname = ncs_files_or_tsd{ii};
    end
    file_list = [file_list ' "' ncs_files_or_tsd{ii} '" '];
end
% Create a temporary event file if the user want's to also show events.
if nargin > 1
    % event_file = ...
    error('NOT IMPLEMENTED YET')
end
cmd = ['"' NEURAVIEW_PATH '"' 'Neuraview ' file_list event_file];
system(cmd)
