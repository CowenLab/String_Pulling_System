function [TIME_USEC, DATA, sFreq, head] = ReadCR_to_matrix(fname,start_ts_usec, end_ts_usec, output_sFreq)
%function [TIME_USEC, DATA, sFreq, head] = ReadCR_to_matrix(fname,start_ts_usec, end_ts_usec, output_sFreq)
% Reads a CSC file and returns the data.
%
% INPUT:
%     fname ... full filename of Cheetah_NT CSC*.dat file
%     start_time to load (in whatever units are the units of the file)
%     end_time to load
%     output_sFreq = if a frequency, the data is resampled at this rate.
%           if a vector, then the output is for just these timestamps (interpolated)
%
% OUTPUT:
%
%      1 timestamps in SECONDS!!!
%      2 the csc data - one to one correspondence with the timestamps.
%      3 the sampling frequency in Hz
%      4 what the units are in. .0001 = 1/10000 of a second.
%
% cowen: works using the neuralynx loaders.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    start_ts_usec = [];
    end_ts_usec = [];
    output_sFreq = [];
end
if nargin < 4
    output_sFreq = [];
end
ts = [];

if isempty(start_ts_usec)
    try
        FieldSelection = [1 0 0 0 1];
        ExtractHeader = 1; ExtractMode = 1;
        ModeArray = 1;
        
        [ts,cr,hd] = Nlx2MatCSC(fname,FieldSelection,ExtractHeader,ExtractMode,ModeArray);
        interval_len = median(diff(ts))/512;
        sFreq = 1e6/interval_len;
    end
    %[ts,cr,sFreq] = ReadCR_partial_load(fname);  %  timestams ts are in 0.1 milliseconds units!!!!!
    if isempty(ts)
        % Assume an old format file.
        [ts,cr,sFreq] = ReadCR_partial_load(fname);  %  timestams ts are in 0.1 milliseconds units!!!!!
        cr = cr';
        ts = ts*100;
    end
else
    try
        FieldSelection = [1 0 0 0 1];
        ExtractHeader = 1; ExtractMode = 1;
        ModeArray = [start_ts_usec end_ts_usec];
        %[ts,sFreq,cr,head] = Nlx2MatCSC(fname,1,0,1,0,1,1,start_ts_usec,start_ts_usec);
        [ts,cr,head] = Nlx2MatCSC(fname,FieldSelection,ExtractHeader,ExtractMode,ModeArray);
        interval_len = median(diff(ts))/512;
        sFreq = 1e6/interval_len;
    end
    %[ts,cr,sFreq] = ReadCR_partial_load(fname,start_ts_usec, end_ts_usec);  %  timestams ts are in 0.1 milliseconds units!!!!!
    %cr = cr'; % For ReadCR_partial_load
    if isempty(ts)
        % Assume an old format file.
        [ts,cr,sFreq] = ReadCR_partial_load(fname,start_ts_usec/100, end_ts_usec/100);  %  timestams ts are in 0.1 milliseconds units!!!!!
        cr = cr';
        ts = ts*100;
    end
end

sFreq = sFreq(1);

if isempty(ts)
    error('Could not load file')
    return
end
DATA=reshape(cr,1,size(cr,1)*size(cr,2));
blockSize = size(cr,1);
nBlocks = size(cr,2);
clear cr; pack; % Big so clear up space.

TIME_USEC = zeros(size(DATA));
ts(end+1) = ts(end) + (ts(end) - ts(end - 1));
dTs = diff(ts)/512;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iBlock = 1:(nBlocks)
    %dT = (ts(iBlock+1)-ts(iBlock))/512;
    TIME_USEC((blockSize * (iBlock-1) + 1):(blockSize * iBlock)) = ...
        linspace(ts(iBlock), ts(iBlock+1) - dTs(iBlock), blockSize);
end
DATA = DATA(:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Resample if required.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(output_sFreq)
    % Interpolate the data so that you know the timestamps are precise
    if length(output_sFreq) == 1
        new_times = TIME_USEC(1):1e6/output_sFreq:TIME_USEC(end);
    else
        new_times = output_sFreq;
    end
    % Spline is slower than interp.
    DATA = interp1(TIME_USEC, DATA, new_times); % interp ensures equal spacing in timestamps and decimates the data.
    TIME_USEC = new_times;
    sFreq = 1e6/mean(diff(TIME_USEC));
    disp(['>>> Resampled ' fname ' to ' num2str(sFreq) ' Hz, ' num2str(length(DATA)) ' points. Start ts: ' num2str(TIME_USEC(1)) ' End: ' num2str(TIME_USEC(end))])
end
