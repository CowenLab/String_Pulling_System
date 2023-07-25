function [W pk_ix PKonWave ] = Spike_finder(LFP,sFreq,thresh,upper_bound,pts_before_and_after,filter_range)
% Finds spikes on the data in LFP where each col is a channel, sFreq is the
% sample rate and nTrodes is a matrix of the cols in LFP that correspond to
% electrodes.
% presumes that the data needs to be filtered unless filter_range is empty.

if nargin < 4
    upper_bound = inf;
end
if nargin < 5
    pts_before_and_after = [];
end
if nargin < 6
    filter_range = [600 6000];
end

if isempty(pts_before_and_after)
    nBefore = 24; % points before and after on the waveform
    nAfter = 24;
else
    nBefore = pts_before_and_after(1);
    nAfter = pts_before_and_after(2);
end

spike_duration_msec = .9; % If there are multiple peaks in this window, take the largest, ignore the other one.

nWavePts = nBefore + nAfter + 1;
PKonWave = nBefore + 1;
nCols = Cols(LFP);

if ~isempty(filter_range)
    % FILTER FOR SPIKES.
    LFP = Filter_for_spikes(LFP,sFreq,filter_range);
end
%rms = mean(sqrt(N(:,1:nTrodes).^2));
%%%%%%%%%%%%%%%%%%%
% Go through each channel and find the channel that creates the lowest RMS
% value..
%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%
%% Identify Spikes
% Find the peaks on every channel.
%%%%%%%%%%%%%%%%%%%%

for iCh = 1:nCols;
    de = [0; diff(LFP(:,iCh)); 0];   % backward derivative
    %finding peaks
    %NOTE THIS DOES NOT GET RID OF MULTIPLE PEAKS!!!
    PIX(de(1:(end-1)) > 0 & de(2:end) < 0 & LFP(:,iCh) > thresh(iCh) & LFP(:,iCh) < upper_bound) = 1;
end
%%%%%%%%%%%%%%%%%%%%
% Get ride of stuff at edges.
%%%%%%%%%%%%%%%%%%%%
PIX(1:(nBefore+1)) = 0;
PIX((end-nAfter):end) = 0;
%%%%%%%%%%%%%%%%%%%%
% Get ride multiple peaks within the spike time window
%%%%%%%%%%%%%%%%%%%%
PIX_ix = find(PIX);
bad_ix = [];
for ii = 1:(length(PIX_ix)-1)
    df = 1e3*(PIX_ix(ii+1)-PIX_ix(ii))/sFreq ;
    if df < spike_duration_msec
        % get rid of the smaller one.
        if max(LFP(PIX_ix(ii),:)) > max(LFP(PIX_ix(ii+1),:))
            bad_ix = [bad_ix; PIX_ix(ii+1)];
        else
            bad_ix = [bad_ix; PIX_ix(ii)];
        end
    end
end
PIX(bad_ix) = 0;

% figure
% plot(LFP(:,1:2))
% hold on
% plot(find(PIX),LFP(find(PIX),1),'r*')

nPIX = sum(PIX);

%%%%%%%%%%%%%%%%%%%%
r  =  repmat(-nBefore:nAfter, nPIX, 1); % index range around peak.
rr =  repmat(find(PIX)', 1, nWavePts);
rrr = r + rr; % Indices of waveforms.
%%
W = zeros(nWavePts,nCols,nPIX);
for iT = 1:nCols
    d = LFP(:,iT);
    W(:,iT,:) = d(rrr');
end

if nargout > 1
    pk_ix = find(PIX);
end
%%%%%%%%%%%%%%%%%%%%
if nPIX == 0
    disp('NO SPIKES FOUND!')
    return
end
%%
if nargout == 0
    figure
    nTrodes = size(W,2);
    wv = [];
    for iT = 1:nTrodes
        wv = [wv squeeze(W(:,iT,:))];
    end
    plot_confidence_intervals(wv)
end