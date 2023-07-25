%% Ripple identification and visualization on a single channel %%

%% load data on potential channel with ripples %%
LFP_file1 = 'amp-D-013.dat';
fp = fopen(LFP_file1,'rb');
LFP1 = fread(fp,'int16');
fclose(fp);

%% load info & meta data %%
infoFile = 'info.rhd';
info     = INTAN_Read_RHD_file(infoFile);
IF = INTAN_Read_RHD_file(); 
sFreq = IF.frequency_parameters.amplifier_sample_rate;

%% convert to uvolt %%
LFP1 = info.bit_to_uvolt_conversion*LFP1; 
%% convert to usec/msec %%
LFP_sFreq = 1250; % sampling frequency

%% decimate data and remove stim artifact if there is one %%
RemStimArt = 0;
if RemStimArt == 1
     trigFile        = 'board-DIN-08.dat'; % load trig file
     TrData          = INTAN_Read_TRIG_file([trigFile]); % read trig file
     minTrigSkipPts  = 100;  % Do not allow triggers within this many pts 
     a=find(TrData==1);b=find(diff([0;a])>minTrigSkipPts);  % Find Triggers

     tArt            = [-LFP_sFreq*0.001 LFP_sFreq*0.5]; % Time window around stm artifiact in ± pts 

     trigtimesPts = a(b); % trig times in pts
     tArtPts         = [trigtimesPts(:,1)+tArt(1) trigtimesPts(:,1)+tArt(2)]; %trig window

     for i = 1:length(tArtPts)
        LFP1(tArtPts(i):tArtPts(i,2))=0;
     end 
end 

raw_ripple = LFP1; 
decimation_factor = 10;
ds_ripple = decimate(double(raw_ripple),decimation_factor);
ds_sFreq = LFP_sFreq/decimation_factor;

% if RemStimArtiFlag == 1  % use spline interpoaltion to remove stim artifact
%             z(:,1:tArtPts(1))                = bsxfun(@minus, z(:,1:tArtPts(1)), z(:,tArtPts(1)));
%             z(:,tArtPts(end)+1:end)          = bsxfun(@minus, z(:,tArtPts(end)+1:end), z(:,tArtPts(end)+1));
%             z(:,tArtPts(1)-1:tArtPts(end)+1) = interp1([tArtPts(1)-1,tArtPts(end)+1]',z(:,[tArtPts(1)-1,tArtPts(end)+1])',tArtPts(1)-1:tArtPts(end)+1,'spline')';
% end

%% filter for ripples, get envelope %%
rip_filter_bandpass_hz = [120 240]; %% edge frequencies
rips = Filter_200hz_simple(ds_ripple,rip_filter_bandpass_hz(1),rip_filter_bandpass_hz(2),ds_sFreq);

msec_window = 25; % window for the envelope
window_points = round(ds_sFreq*(msec_window/1000));
ENV = envelope_cowen(rips); % create envelope
ENV = conv_filter(ENV,hanning(window_points)/sum(hanning(window_points)));

minimum_duration = ds_sFreq*.02;
minimum_inter_interval_period = ds_sFreq*.02;

lower_rip_thresh = (nanstd(ENV)*3); %% thresh for identification
upper_rip_thresh = (nanstd(ENV)*5);

[rip_times, below_times] = find_intervals([ENV], upper_rip_thresh, lower_rip_thresh, ...
    minimum_duration, minimum_inter_interval_period);

sidetimes = ds_sFreq*.02; % number of samples at LFP_sFreq to grab on either side
rip_times_sidetimes =[rip_times(:,1)-sidetimes rip_times(:,2)+sidetimes]; %% rip_times plus sidetimes to add on either side of ripple

%% visualize ripple %%

minfreq = 80;
maxfreq = 300;
numfreq = 75;

frex = logspace(log10(minfreq),log10(maxfreq),numfreq);

for i = 1:length(rip_times)
    ripnum = i; %% choose the ripple number from rip_times
    rip_time = (rip_times_sidetimes(ripnum):rip_times_sidetimes(ripnum,2));
    rip_time_msec = ((rip_time)/(ds_sFreq))*1e3;

    filt_ripple = rips;
    [phase,pow,filtsig] = waveletdecomp(frex,ds_ripple(rip_time)',ds_sFreq,6); 
 
  figure;
  subplot(2,1,1);
    plot(rip_time_msec,ds_ripple(rip_time),'k','LineWidth',3); axis tight;
    title('Wide band');
    set(gca,'visible','off'); set(findall(gca, 'type', 'text'), 'visible', 'on');
%   subplot(3,1,2)
%     plot(rip_time_msec,filt_ripple(rip_time),'b','LineWidth',3); axis tight;
%     title('140-240 Hz') 
%     set(gca,'visible','off'); set(findall(gca, 'type', 'text'), 'visible', 'on');
  subplot(2,1,2);
    contourf(rip_time_msec',frex,pow,numfreq,'linecolor','none');colorbar;
    colormap(jet);
    title(i);
    ylabel('Frequency (Hz)');
    xlabel('Time (ms)');
    
end 

tilefigs
