function SPEC_spike_field_coupling_demo_Vinck2012()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Requires FieldTrip to be in the path (Sadly, this is a huge distribution - DO NOT GET THE LITE VERSION as it does not have the code.).
% Do this by running SPEC_ft_add_fieldtrip_to_path first (only once) or
% adding to your startup.m
%
% https://www.fieldtriptoolbox.org/
% https://www.fieldtriptoolbox.org/tutorial/spikefield/
% https://www.fieldtriptoolbox.org/reference/ft_spiketriggeredspectrum_stat/
% https://www.fieldtriptoolbox.org/reference/ft_connectivity_ppc/
% https://www.fieldtriptoolbox.org/walkthrough/
% https://www.fieldtriptoolbox.org/getting_started/animal/
% Vinck M, van Wingerden M, Womelsdorf T, Fries P, Pennartz CM a. 2010. The pairwise phase consistency: a bias-free measure of rhythmic neuronal synchronization. Neuroimage [Internet] 51:112–122. Available from: http://www.ncbi.nlm.nih.gov/pubmed/20114076
%
% Cowen 2021
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add paths
SPEC_ft_add_fieldtrip_to_path('E:\Temp\fieldtrip-20210128'); % E G
% Load data.
filename = 'E:\Temp\p029_sort_final_01.nex';
spike            = ft_read_spike(filename); % This loads all spikes
cfg              = [];
cfg.spikechannel = {'sig002a_wf', 'sig003a_wf'}; % this just pulls out 2
spike            = ft_spike_select(cfg, spike);
sFreq = spike.hdr.FileHeader.Frequency;
cfg          = [];
cfg.dataset  = filename;
cfg.trialfun = 'SPEC_ft_trialfun_stimon_samples';
cfg          = ft_definetrial(cfg);

% read in the data in trials
cfg.channel   = {'AD01', 'AD02', 'AD03', 'AD04'}; % these channels contain the LFP
cfg.padding   = 10; % length to which we pad for filtering
cfg.dftfreq   = [60-1*(1/10):(1/10):60+1*(1/10) ]; % filter out 60 hz line noise
cfg.dftfilter = 'yes';
data_lfp      = ft_preprocessing(cfg); % read in the LFP

% now we have to reconfig the spikes to map onto the LFP data.
cfg           = [];
cfg.dataset   = filename;
cfg.trialfun  = 'SPEC_ft_trialfun_stimon_samples';
cfg           = ft_definetrial(cfg);
trl           = cfg.trl;

cfg           = [];
cfg.hdr       = data_lfp.hdr; % contains information for conversion of samples to timestamps
cfg.trlunit   = 'samples';
cfg.trl       = trl; % now in samples
 spikeTrials   = ft_spike_maketrials(cfg,spike);
% data_all   = ft_spike_maketrials(cfg,spike);
data_all = ft_appendspike([],data_lfp, spike);


% Spike triggered avg of LFP
cfg              = [];
cfg.timwin       = [-0.25 0.25]; % take 400 ms
cfg.spikechannel = spike.label{1}; % first unit
cfg.channel      = data_lfp.label(1:4); % first four chans
cfg.latency      = [0.3 10];
staPost          = ft_spiketriggeredaverage(cfg, data_all);

% plot the sta
figure
plot(staPost.time, staPost.avg(:,:)')
legend(data_lfp.label)
xlabel('time (s)')
xlim(cfg.timwin)

% FUNALLY COMPUTE THE SPIKE COULING....
if 0
cfg              = [];
cfg.method       = 'mtmfft';
cfg.foilim       = [20 100]; % cfg.timwin determines spacing
cfg.timwin       = [-0.05 0.05]; % time window of 100 msec
cfg.taper        = 'hanning';
cfg.spikechannel = spike.label{1};
cfg.channel      = data_lfp.label;
stsFFT           = ft_spiketriggeredspectrum(cfg, data_all);
end
% ang = angle(stsFFT.fourierspctrm{1})
% mag = abs(stsFFT.fourierspctrm{1})

cfg           = [];
cfg.method    = 'mtmconvol';
cfg.foi       = 20:10:100;
cfg.t_ftimwin = 5./cfg.foi; % 5 cycles per frequency
cfg.taper     = 'hanning';
save('C:\Temp\SPEC.mat')
stsConvol     = ft_spiketriggeredspectrum(cfg, data_all);
%% FINALLY - this actually works but JEEZUS
for k = 1:length(stsConvol.label)

  % compute the statistics on the phases
  cfg               = [];
  cfg.method        = 'ppc0'; % compute the Pairwise Phase Consistency
  excludeChan       = str2num(stsConvol.label{k}(6)); % exclude the same channel
  chan              = true(1,4);
  chan(excludeChan) = false;
  cfg.spikechannel  = stsConvol.label{k};
  cfg.channel       = stsConvol.lfplabel(chan); % selected LFP channels
  cfg.avgoverchan   = 'unweighted'; % weight spike-LFP phases irrespective of LFP power
  cfg.timwin        = 'all'; % compute over all available spikes in the window
  cfg.latency       = [0.3 nanmax(stsConvol.trialtime(:))]; % sustained visual stimulation period
  statSts           = ft_spiketriggeredspectrum_stat(cfg,stsConvol);

  % plot the results
  figure
  plot(statSts.freq,statSts.ppc0')
  xlabel('frequency')
  ylabel('PPC')
end