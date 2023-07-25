function [LFP ,H, all_rec_values, T_usec, OrigRIDs] = ndq_read_ndqcon(ndqcon_file, channels_to_load, intervals_to_load, interval_type, output_precision)
% Reads data from the ndqcon file.
%
%   All timestamps are presumed to be microseconds.
%
%   The reason that times is the last of the 3 parameters is that it takes
%   a fair amount of computational time so the read_ndqcon will not perform
%   these calculations if it is not requested.
%
%   OUTPUT: Returns LFP in DOUBLE precision.
%
% Cowen 2010
%

if nargin < 3
    % load in everything
    intervals_to_load = [];
end

if nargin < 4
    interval_type = 'rec_interval';
end

if nargin < 5
    output_precision = 'double';
end
%
%nrecs = ndq_nrecs(ndqcon_file); % how big is the file?

nBytesPerDatapt = 2; % data is saved as int16 but data is read one byte at a time.

fp = fopen(ndqcon_file,'rb');

if fp == -1
    error(['Could not open ' ndqcon_file])
end

[H,fp] = ndq_read_ndqcon_header(fp);
% ftell(fp)
fseek(fp,-4,'cof'); % The -4 was added to deal with what appears to be a header that is 4 bytest too long. Doing this alignes the data perfectly(enough) with the original CSC data.
fstart = ftell(fp); % Start of the data.
% n_skip_points = round(30000/H.s_freq); % points skipped between each original record in the bin file to generate this file.

if nargin < 2 || isempty (channels_to_load) || isinf(channels_to_load)
    channels_to_load = 1:H.n_channels; % assume you just want all of the channels.
end


if isempty(intervals_to_load)
    intervals_to_load = [1 H.n_recs]; % was negative 1. Why?
    interval_type = 'rec_interval';
end

% NOTE: H will have to be updated if this file is loaded via a partial
% load. (e.g. the start_rec and start_t need to be different)
% % above can be simplified to 
orig_samples_per_interval = round(30000/H.s_freq); % better be a whole number.
%bin_rec_ids_in_LFP_file = 1:orig_samples_per_interval:nrecs;

% Conventions:
%  rec = a record from a particular timestamps (there may be multiple
%    values as a single timestamped record could contain data from multiple
%    channels.
%  data_point = a particular value of data to load (I16)
%
% Convert the passed in intervals to record numbers.
%interval_usec = 1e6/H.s_freq; % interval between samples.
switch interval_type
    case 't_interval'
        % user passes in a nx2 matrix of start and end timestamps
        % Convert the timestmaps
        I = (intervals_to_load - H.start_t); % Reset the start.
        rec_intervals = (I*H.s_freq)/1e6; % Convert to samples. sample = time_usec * sample/usec
        %rec_intervals = round(rec_intervals);
        rec_intervals(:,1) = floor(rec_intervals(:,1));
        rec_intervals(:,2) = ceil(rec_intervals(:,2));
        % Convert these intervals to timstamps.
        t_intervals = intervals_to_load;
    case 't' % TO DO LATER
        % user passes in a vector of timestmaps.
        % read each datapoint in turn (this may be the slowest way to load.
        
    case 'rec_interval'
        % user passes in a nx2matrix of intervals (record numbers, starting with ONE).
        rec_intervals = intervals_to_load;
        %t_intervals = (([intervals_to_load(:,1)-1 intervals_to_load(:,2)])/H.s_freq)*1e6 + H.start_t; % convert to times.
        t_intervals = ((intervals_to_load-1)/H.s_freq)*1e6 + H.start_t; % convert to times.
 
    case 'rec' % TO DO LATER
        % user pases in a vector of record numbers.
        %        recs_to_load = intervals_to_load; % slow perhaps.
        % TO DO LATER
    otherwise
        error('Incorrect interval type')
end
% Determine how to skip and load the data.
% Data starts here (I16).
%%
nCh = length(channels_to_load); % This is NOT th enumber of channels in the record!!! THis is the column number of channels to get.

LFP = []; T_usec = [];OrigRIDs = [];
% cowen 2011 RecBlockSize = nBytesPerDatapt * nCh; % this seems wrong! It shoud be the number of stored bytes, not what you ask out.
RecBlockSize = nBytesPerDatapt * H.n_channels; % this seems right.
all_rec_values = [];

for iInterval = 1:Rows(rec_intervals)
    nrecs = rec_intervals(iInterval,2)-rec_intervals(iInterval,1) + 1;
    outrecs = nrecs;
    all_rec_values = [all_rec_values rec_intervals(iInterval,1):rec_intervals(iInterval,2)];
    
    for iCh = 1:nCh
        % Move to the start of the file, then to the end of the header,
        % then move ahead by the number of points * (channel_id-1)
        fseek(fp,2*(channels_to_load(iCh)-1) + fstart ,'bof');
        % Given that we are reading intervals, move forward by the number
        % of records.
        % rec_intervals is NOT zero based (first rec is record one so subtract one in the fseek).
        fseek(fp, (rec_intervals(iInterval,1)-1) * RecBlockSize ,'cof'); % move to the beginning of the data block.
        % if there is a skip, then skip n record blocks between samples.
        % Remember that each read is only one byte so you need to mult by
        % nBytesPerDatapt.
        % Keep in native format.
        if iCh == 1
            % If it's the first channel, allocate some space for the
            % record. Note, there is no guarantee that this will return a
            % complete record if 
            % cowen 2011 tmp = fread(fp,outrecs,'int16=>int16', nBytesPerDatapt*(nCh-1)); % Skip over to the channel.
            if nCh == 1
                O = fread(fp,outrecs,'int16=>int16');
            else
                tmp = fread(fp,outrecs,'int16=>int16', nBytesPerDatapt*(H.n_channels-1)); 
                O = zeros(Rows(tmp),nCh,'int16');
                O(:,iCh) = tmp;
            end
            if outrecs ~= Rows(O)
                disp(['Danger, could not retrieve all records in interval ' num2str(t_intervals(iInterval,1)) ' ' num2str(t_intervals(iInterval,2)) '. Truncating.']);
            end
        else
           % cowen2011 O(:,iCh) = fread(fp,outrecs,'int16=>int16', nBytesPerDatapt*(nCh-1)); % Skip over the channel.
            O(:,iCh) = fread(fp,outrecs,'int16=>int16', nBytesPerDatapt*(H.n_channels-1)); % Skip over the channel.
        end
        fprintf('ch%d ',channels_to_load(iCh))
    end
    %  finished interval - now add to the master thing (time consuming...
    %  Could be more efficient.
    if Rows(rec_intervals) > 1
        LFP = [LFP; O];
    else
        LFP = O;
    end
    
    if nargout > 3
        tim = 1e6*((rec_intervals(iInterval,1):rec_intervals(iInterval,2))-1)/H.s_freq; % Remeber, time starts at 0, that's why we subtract 1
        %        tim = linspace(t_intervals(iInterval,1), t_intervals(iInterval,2), outrecs)';
        T_usec = [T_usec; tim(1:Rows(O))];  % cuts off times if the last block was not complete.
    end  
end
if nargout > 4
    OrigRIDs = (all_rec_values-1) * orig_samples_per_interval + 1;
end
T_usec = T_usec(:) + H.start_t;
fclose(fp);

switch output_precision
    case 'double'
        % default
        LFP = double(LFP); % I do not keep it in it's native int16 because it leads to very strange errors if you pass it into other matlab functions which can sometimes take days to figure out. 
    case 'single'
        LFP = single(LFP); % I do not keep it in it's native int16 because it leads to very strange errors if you pass it into other matlab functions which can sometimes take days to figure out. Single works with most matlab functions.
    case 'int16'
        % native
    otherwise
        error('Unknown precision')
end

all_rec_values = all_rec_values(:);

H.start_t = t_intervals(1);
H.start_rec = rec_intervals(1);
H.rec_intervals = rec_intervals;
H.t_intervals = t_intervals;

