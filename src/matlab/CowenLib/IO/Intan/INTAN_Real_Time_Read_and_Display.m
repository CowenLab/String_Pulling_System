function [status] = INTAN_Real_Time_Read_and_Display(dirname,recs_back,channels,DIN)
% function [status] = INTAN_Real_Time_Read_and_Display(dirname,channels,recs_back)
%
% Plot the most recent group of recs on the intan system. Plot it
% you could also output this chunk (D) to a smrx file for viewing in spike
% 2.
% Cowen.

RHD = INTAN_Read_RHD_file;
sFreq = RHD.frequency_parameters.amplifier_sample_rate;

if nargin < 4
    DIN = 'board-DIN-02.dat'; % 
end
if nargin < 3
    channels = 1:4:30; % 
end
if nargin < 2
    recs_back = sFreq*20; % 
end
if nargin < 1
    dirname = uigetdir(); % 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load digital signal from FSCV

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fclose all
str = 'amp-D-';

dname = fullfile(data_dir,DIN);
dp = fopen(dname,'rb');
status = fseek(dp, 0, 'eof');
end_rec = ftell(dp);
end_rec = floor(end_rec/2)*2; % make sure we end on a full rec as there are 2 bytes per record.
start_rec = end_rec - 2*recs_back;
nrecs = end_rec - start_rec;
fclose(dp);
Dn = zeros(nrecs/2,1);

dname = fullfile(data_dir,DIN);
dp = fopen(dname,'rb');
loc = fseek(dp, start_rec ,'bof');
DIN_evts = fread(dp, nrecs/2, 'int16');
fclose(dp);


fname = fullfile(dirname,sprintf([str '%03d.dat'],channels(1)));
fp = fopen(fname,'rb');
status = fseek(fp, 0, 'eof');
end_rec = ftell(fp);
end_rec = floor(end_rec/2)*2; % make sure we end on a full rec as there are 2 bytes per record.
start_rec = end_rec - 2*recs_back;
nrecs = end_rec - start_rec;
fclose(fp);
D = zeros(nrecs/2,length(channels));
for iCh = 1:length(channels)
    fname = fullfile(dirname,sprintf([str '%03d.dat'],channels(iCh)));
    fp = fopen(fname,'rb');
    loc = fseek(fp, start_rec ,'bof');
    D(:,iCh) = fread(fp, nrecs/2, 'int16');
    fclose(fp);
end
fclose all
figure(1)
clf
skip = 1;
plot_LFP(D(1:skip:end,:),sFreq/skip,[],channels)
   