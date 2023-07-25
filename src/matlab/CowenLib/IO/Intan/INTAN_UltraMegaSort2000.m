function spikes = INTAN_UltraMegaSort2000(fname, sort_it, sFreq, artifact_threshold)
%Continuous amplifier data is basically indistinguishable from the tetrode
%files carved out of the AMPX system. This function is a copy/paste job
%that changes how the metadata becomes known to the Kleinfeld script.
%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spike sorting using UMS2000 from the David Kleinfeld Lab.
% Presumes that the dat file has been properly re-referenced,
% AND only contains channels from ONE nTrode...
% This is a problem - can't fit this on a SSD for large files --- will
% probably have to re-reference on the fly.
%
% INPUT: fname of the file to extract spikes and/or to sort.
%        sort_it = a t/f flag - of whether to to sort or just extract.
% Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters
%fname = 'test_Cowen_Chnl_12_13_14_15.dat';
if nargin < 4
    artifact_threshold = [];
end
if nargin < 2
    sort_it = false;
end
[~, fname_root, e] = fileparts(fname);
% param_file = fullfile(p,[fname_root '.mat']);
%out_file = fullfile(p,['spks_' fname_root '.mat']);
% Extract the channel IDs from the file name.
% e.g. test_Cowen_Chnl_12_13_14_15.dat
ix = findstr(fname_root,'Chnl_');
remain = fname_root(ix+5:end);
count = 1;
channels = [];
while ~isempty(remain)
    [st, remain] = strtok(remain,'_');
    channels(count) = str2num(st);
    count = count + 1;
end
% Load the data
tic
disp('Load')
D = INTAN_Load_Dat(fname, sFreq, length(channels), 1:length(channels),true); % ASSUMES THE DATA IS PRE_FILTERED
% NOTE: There is no timestamp data here! Just records from the start of
% recording.
toc
if ~isempty(artifact_threshold)
    artifIX = max(D,[],2) > artifact_threshold;
else 
    artifIX = [];
end
% TODO REMOVE TEH ARTIFACT! Pass in a set of start and end times and then
% interpolate between them. This is then passed to filter for spikes and
% these points are zeroe out at the end sothat no spikes are detected at
% these points.

% Filter for spikes
disp('Filter')
for ii = 1:size(D,1)
    D(ii,:) = Filter_for_spikes(D(ii,:)', sFreq)';
end
% 

figure(1)
clf
plot_LFP(D(:,1:sFreq)',sFreq);

spikes = ss_default_params(sFreq);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract the spikes from the data. In practice, I should do a pre-run of
% this function for really big files that do not fit into memory.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
disp('ss_detect')

nRecs = size(D,2);
mins_recording = nRecs/sFreq/60;

if mins_recording > 100
    % break up the data into 60 minute sections and extract each section
    % separately.
        
    nIntervals = ceil(nRecs/(sFreq*60*60)); % break it into hour chunks.
    intervals = round(linspace(0,nRecs,nIntervals+1));
    disp(['Big spike file. Breaking it up into ' num2str(nIntervals-1) ' hour long chunks for threshold detection.'])
    for ii = 1:(nIntervals-1)
        st = intervals(ii)+1;
        ed = intervals(ii+1);
        spikes = ss_detect({double(D(:,st:ed)')},spikes);
    end
else
    % Detect everything at once.
    spikes = ss_detect({double(D')},spikes);
end
toc
%save(out_file,'spikes');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Align spikes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic
disp('ss_align')
spikes = ss_align(spikes);
spikes.NOTE = 'time in sec from the start of recording';

toc
% My guess is that spikes contains the time from the start of recording in
% sec.
%save(out_file,'spikes');
% Also save in a format that Neuralynx may recognize (only works for
% tetrodes.

if sort_it
    % Sort the data as well..
    disp('Clustering Data')
    
    tic
    disp('ss_kmeans')
    spikes = ss_kmeans(spikes);
    toc
    
    spikes = ss_energy(spikes);
    spikes = ss_aggregate(spikes);
    %save(out_file,'spikes');
    %splitmerge_tool(spikes)
end
