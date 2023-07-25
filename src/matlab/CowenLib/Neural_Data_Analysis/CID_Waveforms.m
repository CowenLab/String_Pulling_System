function [O] = CID_Waveforms(CID,root_data_dir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function [WV, hpwidth, ptwidth, AC, ACC, HI, HIC] = CID_Waveforms(CID,root_data_dir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Given the CellID (CID), return the waveform information. Presume it is
% stored in the clustersummary.mat file in the 'Data directory' in the
% tfiles subdirectory.
%
% MANY PRESUMPTIONS: tfiles labelled as TT1_4.t, clustersummary as
%    TT1_ClusterSummary_4.mat.
%
% INPUT: vector of cellids (see Cell_ID).
%        the root data directory where all of the session data can be
%        found.
%
% OUTPUT: Waveforms and other goodness.
%
%   (animal, session, nTrode, cluster, subsession)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin <2
    root_data_dir = Data_dir;
end
npts = 60;
[FN]                     = CID_get_filenames(CID,root_data_dir);
sFreq                    = PC_sampling_rate(CID);
O.MeanWaveform           = zeros(length(CID),4,32)*nan;
O.SmoothWV               = zeros(length(CID),npts)*nan;
O.MeanWaveformXAxisMsec  = zeros(length(CID),32)*nan;
O.AutoCorr               = zeros(length(CID),250)*nan;
O.AutoCorrXAxisMsec      = zeros(length(CID),250)*nan;
O.HistISI                = zeros(length(CID),500)*nan;
O.HistISICenters         = zeros(length(CID),500)*nan;
O.hpwidth                = zeros(length(CID),1)*nan; % Average across dimensions.
O.ptwidth                = zeros(length(CID),1)*nan; % Average across dimensions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
O.SmoothWVXAxisMsec = linspace(-.28,.8,60);

for ii = 1:length(FN.cluster_summary)
    try
        load(FN.cluster_summary{ii});
        % Compute the waveform - and correct to be in msec.
        O.MeanWaveform(ii,:,:) = CI.MeanWaveform;
        O.MeanWaveformXAxisMsec(ii,:) = [-8:(31-8)].* (1e3/sFreq(ii));
        O.SmoothWV(ii,:) = interp1(O.MeanWaveformXAxisMsec(ii,:),nanmean(CI.MeanWaveform),O.SmoothWVXAxisMsec,'spline',nan);
        O.AutoCorr(ii,:) = CI.AutoCorr(:)';
        O.AutoCorrXAxisMsec(ii,:)  = CI.AutoCorrXAxisMsec(:)';
        O.HistISI(ii,:)   = CI.HistISI(:)'; 
        O.HistISICenters(ii,:)  = CI.HistISICenters(:)';
    end
    %fprintf('.')
end
hpw = zeros(length(CID),4)*nan;
ptw = zeros(length(CID),4)*nan;
fprintf('\n')
for ii =1:4
    wv = squeeze(O.MeanWaveform(:,ii,:));
    i = find(std(wv')~=0); % measure of a bad channel
    [hpw(i,ii) ptw(i,ii)] = Spike_width(wv(i,:));
    fprintf('*')
end
O.hpwidth = nanmean(hpw')';
O.ptwidth = nanmean(ptw')';
% Convert to msec - unfortunately, this is a kludge!
O.SpikeSampleFreq = CID_SpikeSampleFreq(CID);

O.hpwidth = 1000*O.hpwidth./O.SpikeSampleFreq;
O.ptwidth = 1000*O.ptwidth./O.SpikeSampleFreq;
