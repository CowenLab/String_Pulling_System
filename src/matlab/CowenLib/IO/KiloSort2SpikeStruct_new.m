
function out = KiloSort2SpikeStruct_new

%% Function to extract cluster Ids, peak channels, mean waveforms, and
%  spike times for clusters marked 'good' in Kilosort

% ** Must run script in folder with data (.dat), rez, and spike_clusters.npy **

%  OUTPUT
%  out.cluster_id_good = cluster identifications from Kilosort
%  out.peakChan_good = channel num with maximum amplitude template for each cluster
%  out.meanWave_good = mean waveforms for wach cluster over set window
%  out.spikeTimes_good = spike times for each cluster in cell format 

%   Wilhite 6/14/19

% load in raw data
load('rez.mat');
fid = fopen(rez.ops.fbinary, 'r');
NchanTOT = rez.ops.NchanTOT;
dat = fread(fid, [NchanTOT inf], '*int16');
dat = dat * 0.195; % convert to microvolts per INTAN
fclose(fid);

% organize data with chanMap, remove unconnected channels
dat = dat(rez.ops.chanMap(rez.connected),:);
win = [-75:75]; % number of samples before and after spike for averaging

% extract info from rez
spikeTimes     = rez.st3(:,1);
spikeClusters = double(readNPY('spike_clusters.npy'));
spikeTemplates = rez.st3(:,2);

% get raw data around spiketimes
WAVE = zeros(size(dat,1),numel(win),numel(spikeTimes), 'int16');
for i = 1:length(spikeTimes)
   spkwin = spikeTimes(i) + win; 
    WAVE(:,:,i) = dat(:,spkwin);
end

% find channel number with maximum amplitude template for each cluster
peakChannel = zeros(size(spikeClusters));
uClusters = unique(spikeClusters);
for c = 1:length(uClusters)
    clust     = uClusters(c);
    I         = spikeClusters == clust;
    templates =  unique(spikeTemplates(I));
    
   t = squeeze(range((rez.dWU(:,:,templates)),1));
   m = max(max(t));
   if any(size(t) ==1)
       chidx = find(t == m);
   else
       [chidx, ~] = find(t == m);
   end
   peakChannel(I) = chidx;
    
end

% break up into individual clusters
for i = 1:length(uClusters)
  for ii = uClusters(i)
    timesClu = find(spikeClusters == ii);
    peakChannelClu = peakChannel(timesClu);
    channelClu = unique(peakChannelClu);
    waves = squeeze(double(WAVE(channelClu, :,timesClu)));
    peakchan(i,:) = channelClu;
    spiketimes{i,:} = timesClu;
    meanwave(i,:)  = nanmean(waves,2);
  end 
end 

% confine to good clusters
C = tdfread('cluster_group.tsv');
Clus_good = find(ismember(C.group,{'good'})); % changed from 'unsorted' to 'good' for phy2, 1-based

out.peakChan_good = peakchan(Clus_good);
  [B,I] = sort(out.peakChan_good); % sort channels and out. from low to high
out.cluster_id_good = uClusters(Clus_good);
out.meanWave_good = meanwave(Clus_good,:);
for i = 1:length(out.meanWave_good(:,1))
  out.meanWave_good(i,:) = out.meanWave_good(i,:)-mean(out.meanWave_good(i,:)); % remove DC offset
end 
out.spikeTimes_good = spiketimes(Clus_good,:);
  
out.peakChan_good = out.peakChan_good(I)
out.cluster_id_good = out.cluster_id_good(I);
out.meanWave_good = out.meanWave_good(I,:);
out.spikeTimes_good = out.spikeTimes_good(I);

figure
for i = 1:length(ans.meanWave_good(:,1))
  subplot(1,length(ans.meanWave_good(:,1)),i)
  plot(ans.meanWave_good(i,:),'LineWidth',2);axis tight; 
  ylabel('\muV');xlabel('samples'); box off; ylim([-220 75]);
  title(['Ch:',num2str(ans.peakChan_good(i,:))]);
  if i > 1
      set(gca, 'YTick', []); ylabel([]);xlabel([]);
  end
end 
