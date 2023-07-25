function [EEG_TIME_AND_DATA, header, calced_sFreq] = nlx2matCSC_Matrix(EEG_filename,original_interval_usec)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Load the eeg data
%Returns time in microseconds.
% I JUST FOUND A BIIIG BUG. HAVING A MATRIX OF INTERVAL START AND END TIMES
% SCREWS THING UP IMMENSELY> IT JUST LOADS IN DATA FROM THE FIRST TIMESTAMP
% TO THE FIRST TIMESTAMP OF THE NEXT INTERVAL. I FIXED THIS. TRY USING
% Read_nlx_CR_files INSTEAD. IT ALLOWS YOU TO SELECT AN OUTPUT FREQUENCY
% AND MULTIPLE CHANNELS.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load in the target records.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
EEG_TIME_AND_DATA = [];
FieldSelection = [1 0 1 0 1];
ExtractHeader = 1;
header = []; calced_sFreq = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist(EEG_filename,'file')
    pwd
    error(['No such file ' EEG_filename])
end
[p,n,e] = fileparts(EEG_filename);
if ~strcmpi(e,'.ncs')
    pwd
    error(['Not a .ncs file ' EEG_filename])
end
if nargin == 1 || isempty(original_interval_usec)
    original_interval_usec = [nan nan];
end

for interval_count = 1:Rows(original_interval_usec)
    interval_usec = original_interval_usec(interval_count,:);
    if isnan(interval_usec(1))
        ModeArray   = [];
        ExtractMode = 1;
    else
        ModeArray   = interval_usec;
        ExtractMode = 4;
    end
    try
        [TimeStamps_us, sFreq, EEG_data, header] =  Nlx2MatCSC( EEG_filename, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
    catch
        pwd
        disp([ ' Nlx2MatCSC CRASHED LOADING: ' EEG_filename]);
        return
    end
    interval_usec = [TimeStamps_us(1) TimeStamps_us(end)];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If TimeStamps_us does not exist, is a likely indicator that this
    % isn't a file with a header so use partial_load.
    % I think this 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~exist('TimeStamps_us','var')
        disp('Could not used neuralynx reader. Using ReadCR_partial_load (this can crash!!)')
        [EEG_data] = Read_nlx_CR_files({EEG_filename},[]);  %  timestams ts are in 0.1 milliseconds units!!!!!
        TimeStamps_us = TimeStamps_us * 100;
        EEG_data = EEG_data'; 
    end
    
    %     sFreq       = sFreq(1);
    usec_per_sample = median(diff(TimeStamps_us))/512;
    %%%%%%%%%%%%%%%%%%%
    % Trust but verify.
    %%%%%%%%%%%%%%%%%%%
    calced_sFreq = (1/usec_per_sample)* 1e6;
    norig_TimeStamps_us = length(TimeStamps_us);
    %%%%%%%%%%%%%%%%%%%  
    EEG_data = EEG_data'; % The convention is each row is a sample so convert
    % Get a timestamp for each record (so no more blocks)
    TS_matrix = repmat(TimeStamps_us(:),1,size(EEG_data,2));
    % Do this in a for loop instead of creating another matrix to save space.
    for ii = 2:size(EEG_data,2)
        TS_matrix(:,ii) = TS_matrix(:,ii) + (ii-1) * usec_per_sample;
    end
    % 
    EEG_TIME_AND_DATA   = [EEG_TIME_AND_DATA; reshape(TS_matrix',numel(TS_matrix),1) reshape(EEG_data',numel(EEG_data),1)];
end