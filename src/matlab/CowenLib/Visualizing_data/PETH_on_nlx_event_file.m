function h = PETH_on_nlx_event_file(Evt_filename,data_filename, filetype, parameters, event_codes, event_descriptions )
% Creates PETHs for each unique event found in the neuralynx event file.
%function h = PETH_on_nlx_event_file(Evt_filename,data_filename, filetype, parameters)
% INPUT: event filename
%        data file name (.ntt,.nse, .t  etc...)
%        type of data file ('TT', 'SE','ST', 't')
%        paramters(optional): [ binsize_msec, time_before_msec, time_after_msec] - the parameters for the PETH
% OUTPUT
%        PETH for each event.
% cowen
% NOTE: You must supply the full path, not the partial one.

if nargin < 4
    event_codes = [];
    event_descriptions = [];
    binsize_msec = 5;
    time_before_msec = 1000;
    time_after_msec = 1500;
else
    binsize_msec = parameters(1);
    time_before_msec = parameters(2);
    time_after_msec = parameters(3);
end    

%[eT, EventIDs, Ttls, Extras, EventStrings, NlxHeader] = Nlx2MatEV(Evt_filename,1,1,1,1,1,1);
FieldSelection = [1 1 1 1 1];
ExtractHeader = 0; ExtractMode = 1;
ModeArray = [ 0 4 9];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[eT, EventIDs, Ttls, Extras, EventStrings] = Nlx2MatEV( Evt_filename, FieldSelection, ExtractHeader, ExtractMode, ModeArray );

FieldSelection = [1 0 0 0 0];
ExtractHeader = 0; ExtractMode = 1;
ModeArray = [ ]; % Get all records

filetype = upper(filetype);
switch filetype
case 'SE','TT','ST'
    sT = nlx2MatSpike( data_filename, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
    %    [sT] = Nlx2MatSE(data_filename,1,0,0,0,0,0);
    %    [sT] = Nlx2MatTT(data_filename,1,0,0,0,0,0);
    %    [sT] = Nlx2MatST(data_filename,1,0,0,0,0,0);
case 'NCS'
    % Restrict the loaded range to the periods with the event data.
    start_time = min(eT) - 1e6;
    end_time = max(eT) + 1e6;
    %     ExtractMode = 4;
    %     ModeArray = [ start_time end_time];
    %     
    %     FieldSelection       = [1 0 1 0 1];
    %     [NCStimes, sFreq, NCSData] = Nlx2MatCSC(data_filename, FieldSelection, ExtractHeader, ExtractMode, ModeArray );   
    %     NCSData = NCSData(:);
    %     sFreq = sFreq(1);
    %     blockSize = size(NCSData,1);
    %     nBlocks = length(NCStimes);
    %     dT = 1e6/sFreq; % in nlx tstamps
    %     TIME = zeros(size(NCSData));
    %     time_range = [NCStimes NCStimes(end) + 512*dT];
    %     
    %     for iBlock = 1:(nBlocks)
    %         %DisplayProgress(iBlock, nBlocks-1);
    %         TIME((blockSize * (iBlock-1) + 1):(blockSize * iBlock)) = ...
    %             linspace(time_range(iBlock), time_range(iBlock+1) - dT, blockSize);
    %     end
    try
        [EEG.original_ts, EEG.original_data, EEG.sampling_freq] = ...
            ReadCR_to_matrix(data_filename, start_time/100, end_time/100 );
        loaded_file = 1;
    catch
        %[EEG.original_ts, EEG.ChannelNumbers, EEG.SampleFrequencies,Samples] = ...
        %   nlx2matCSC(f{eeg_idx},1,1,1,0,1,0,EVT.Stim(1) - 10*1e6 ,EVT.Stim(end) + 10*1e6 );
        disp(['Could no load ' data_filename])
    end
    
case 'T'
    sT = load_tfiles(data_filename);
    sT = sT*1e2; % Convert to uSec
case 'TSTXT'
    sT = load(data_filename);
otherwise
    error('wrong file type specified')
end

u = unique(Ttls);

if isempty(event_codes)
    event_codes = u;
    event_descriptions{length(event_codes)} = [];
end

for ii = 1:length(event_codes)
    figure
    idx = find(Ttls == event_codes(ii));
    nevts = length(idx);
    if nevts > 200
        disp('Too many events, reducing to random subset')
        r = randperm(length(idx));
        idx = sort(idx(r(1:200)));
    end
    %
    if strcmp(filetype,'NCS')
        PETH_EEG([EEG.original_ts(:)/100,EEG.original_data(:)], sFreq ,eT(idx)/1e6,time_before_msec/1e3,time_after_msec/1e3,[]);
    else
        Align_spike_times(sT/100,eT(idx)/100,binsize_msec,time_before_msec,time_after_msec);
    end
    title([data_filename '  ' event_descriptions{ii} ' ' num2str(event_codes(ii)) ' nevnts = ' num2str(nevts)])
    saveas(gcf,['event_' num2str(event_codes(ii))],'png')
end
