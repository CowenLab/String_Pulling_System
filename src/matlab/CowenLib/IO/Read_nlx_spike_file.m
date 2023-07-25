function [t,wv,hd] = Read_nlx_spike_file(fn, records_to_get, record_units)
%  fn = file name string
%    records_to_get = an array that is either a range of values
%    record_units = 1: timestamp list.(a vector of timestamps to load (uses binsearch to find them in file))
%                   2: record number list (a vector of records to load)
% 					3: range of timestamps (a vector with 2 elements: a start and an end timestamp)
% 					4: range of records (a vector with 2 elements: a start and an end record number)
% 					5: return the count of spikes (records_to_get should be [] in this case)
%                   6: Get all waveforms and timestamps.
% 	 if only fn is passed in then the entire file is opened.
%    if only fn is passed AND only t is provided as the output, then all 
%       of the timestamps for the entire file are returned.
% 
% output:
%    [t, wv] -
%    t = n x 1: timestamps of each spike in file
%    wv = 32 x nChannels x nWaveforms : Units are in microvolts.
%
% Cowen (2009) Wrapper for nlx function. (NOTE: Works on any nlx file).
% MAKE SURE THAT Nlx2MatSpike is at least v4 as v<4 sucks and crashes.
% NOTE v4 SUCKS AS WELL. It fails to read certain records and it is zero
% based!!!!
if nargin == 1
    record_units = 6;
end
FieldSelection(1) = 1;
FieldSelection(2) = 0;
FieldSelection(3) = 0;
FieldSelection(4) = 0;
FieldSelection(5) = 1;
ExtractHeader = 1;
t = [];
wv = [];
%
switch record_units
    case 1
        % Vector of timestamps.
        ExtractMode = 5;
        ModeArray = unique(records_to_get);
        [t, wv, hd] = Nlx2MatSpike( fn, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
        %t = Nlx2MatSpike( fn, [1 0 0 0 0 ], 0, 1, 0 );
    case 2
        % Vector of record ids
        ExtractMode = 3;
        ModeArray = unique(records_to_get) - 1; % Nlx2MatSpike records start at zero so subtract 1.
        [t, wv, hd] = Nlx2MatSpike( fn, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
    case 3
        ExtractMode = 4;
        ModeArray(1) = records_to_get(1); 
        ModeArray(2) = records_to_get(2);
        [t, wv, hd] = Nlx2MatSpike( fn, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
    case 4
        % Record number list
        ExtractMode = 2;
        ModeArray(1) = records_to_get(1) - 1; % Nlx2MatSpike records start at zero so subtract 1.
        ModeArray(2) = records_to_get(2) - 1;
        [t, wv, hd] = Nlx2MatSpike( fn, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
    case 5
        ExtractHeader = 1;
        ExtractMode = 1;
        FieldSelection(5) = 0;
        ModeArray(1) = 0;
        [t hd] = Nlx2MatSpike( fn, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
        t = length(t); 
    case 6 % Get everything
        ExtractMode = 1;
        ModeArray(1) = 0;
        [t wv hd] = Nlx2MatSpike( fn, FieldSelection, ExtractHeader, ExtractMode, ModeArray );
    otherwise
end
t = t(:);
hd = Read_nlx_header(hd);
if ~isempty(wv)
    for ii = 1:length(hd.ADBitVolts)
        wv(:,ii,:) = wv(:,ii,:) * hd.ADBitVolts(ii)*1e6; % Convert to microvolts.
    end
end

if 0 % Old way of arranging the data - we'll go with neuralynx on this.
    if record_units < 5
        % This is stupid, but for mclust we need to add some dummy dimensions.
        % New is 32 2  8588
        % wv = n x 4 x 32 waveforms
        wv = permute(wv,[3 2 1]);
%        nRecs = length(t);
        %    wv = cat(2,wv,zeros(nRecs,2,32)); % Tac on the columns.
    end
end
        
