function [OUT, sFreq, saturation_times, head] = ReadCR_cowen(cr_file, StartTS, EndTS, new_sample_rate, use_nlx_reader)
%function [OUT] = ReadCR_cowen(cr_file, StartTS, EndTS, new_sample_rate, use_nlx_reader)
% Read the CR data. It can read the old format data from the unix boxes and
% with the use_nlx_reader parameter, read using the new nlx readers.
%
% cowen 2013
% Cowen 2019 - found problems with StartTS and EndTS. Put in an error for
% now.
head = [];
saturation_times = [];
sFreq = [];
OUT = [];

if nargin < 2
    StartTS = [];
    EndTS = [];
    new_sample_rate = [];
end
if nargin < 3
    StartTS = [];
    EndTS = [];
    new_sample_rate = [];
end

if nargin < 4
    new_sample_rate = [];
end

if nargin < 5
    use_nlx_reader = false;
end

if ~exist(cr_file,'file')
    if exist([cr_file '.gz'],'file')
        gunzip([cr_file '.gz'])
        disp(['uncompressed ' cr_file])
        delete([cr_file '.gz'])
    elseif exist([cr_file '.zip'],'file')
        unzip([cr_file '.zip'])
        disp(['uncompressed ' cr_file])
        delete([cr_file '.zip'])
    else
        error('could not find file')
        cr_file
    end
end

%H = Read_nlx_header(cr_file); % don't know how to read the header - think we have to do this by hand.

if use_nlx_reader
    sample_units = 1e6;
    if isempty(StartTS)
        ExtractMode = 1;
        ModeArray = 1;
    else
        error('This has not been working consistently. Double check. Failed when you had a multi-row st and ed time')
        ExtractMode = 4;
        ModeArray = round([StartTS EndTS]);
    end
    ExtractHeader = 1;
    FieldSelection = [1 0 0 0 1];
    try
        [CR.ts,CR.dd,tmp] = Nlx2MatCSC(cr_file,FieldSelection,ExtractHeader,ExtractMode,ModeArray);
    catch
        ModeArray
        cr_file
        disp('Could not load data')
        return
    end
    interval_len = median(diff(CR.ts))/512;
    CR.sFreq = 1e6/interval_len;
    head = Read_nlx_header(tmp);
else
    sample_units = 1e4;
    if isempty(StartTS)
        CR = ReadCR(cr_file); % this is for the old Neuralynx data. New data will have differnet procedures for loading.
    else
        CR = ReadCR(cr_file,StartTS,EndTS); % this is for the old Neuralynx data. New data will have differnet procedures for loading
    end
end
%
if any(diff(CR.ts)<=0)
    disp(['WARNING/ERROR: NON-INCREASING TIMESTAMPS. The raw data may be corrupted in ' cr_file])
    disp('Getting rid of strange record')
    BIX = CR.ts < 10 | CR.ts > 1e11;
    CR.ts(BIX) = [];  CR.dd(:,BIX) = [];
    TIX = false(size(BIX));
    while (any(TIX))
       TIX = [ diff(CR.ts) inf] < 0;
       TIX = conv(TIX,[1 1],'same');
%        BIX = BIX | TIX;
       CR.ts(TIX>0) = [];  CR.dd(:,TIX>0) = [];
       TIX = diff(CR.ts) < 0;

    end
%     if 
%        CR.dd
%         
%         OUT
end

CR2 = CR2EEG(CR,true); % converts the block structure of CR into a sane structure with times and columns.
% badST = find(diff(CR2(:,1))< 0,1,'first');
% CR2(badST-1:end,:) = [];
% Nothing is perfect though - there are some weird timestamps in these
% data... There are also blank spots between recording epochs.
CR2 = sortrows(CR2);
ix = find(diff(CR2(:,1)) < 1);
while ~isempty(ix)
    CR2(ix,:) = [];
    ix = find(diff(CR2(:,1)) < 1);
end
BADIX = CR2(:,1) < 1;
CR2(BADIX,:) = [];
% look for non-increasing timestmaps;
BADIX = [false;(diff(CR2(:,1))) < 1];
CR2(BADIX,:) = [];
SATIX = abs(CR2(:,2))>2040; % assumes 12 bit acquisition. A little less to be conservative.
saturation_times = CR2(SATIX,1);
% empirically determine the sampling frequency here...
sFreq = sample_units/(median(diff(CR2(:,1))));
% Interp the data.
secs_of_data = (CR2(end,1)- CR2(1,1))/sample_units;
nSamples = round(secs_of_data*sFreq);
OUT = zeros(nSamples,2);
OUT(:,1) = linspace(CR2(1,1),CR2(end,1),nSamples);
OUT(:,2) = interp1(CR2(:,1),CR2(:,2),OUT(:,1)); % NOTE: this can change the values so that the max/min is no longer 2048
sFreq = sample_units/(OUT(2,1) - OUT(1,1)); % update for precision's sake.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Resample IF the user requests it.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(new_sample_rate)
    LFP = resample(OUT(:,2),OUT(:,1)/1e6,new_sample_rate);
    T = linspace(CR2(1,1),CR2(end,1),length(LFP));
    %      LFPo = resample(OUT(:,2),new_sample_rate, round(sFreq));
    %      To = linspace(OUT(1,1),OUT(end,1),length(LFP));
    OUT = [T(:) LFP(:)];
    sFreq = sample_units/(T(2) - T(1));
end
