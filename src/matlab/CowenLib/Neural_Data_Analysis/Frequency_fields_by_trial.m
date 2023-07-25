function [FF,SD,OC] = Frequency_fields_by_trial(POS,LFPpos,n_place_bins,RANGES,bands)
%function [MN,SD,OC] = Frequency_fields_1D(POS,LFPpos,n_place_bins,bands)
%
% Place field but for frequency bands - or any continuous data (e.g. EMG)
%
% INPUT: POSITION: time, x
%        LFP: Each col is a filtered lfp signal (each col is a frequency
%          band). This must be ALIGNED with the POS data so it's the same
%          number of rows as the position data.
%        n_place_bins = resolution of the position plotting OR pass in a vector
%        of bin edges.
%        band_labels (optional) - for plotting.
%
% OUTPUT: MN mean value of LFPpos at each location
%         SD std of LFPpos at each location
%         OC occupancy (amount of times each spot was visited) - convert to
%            seconds by dividing by tracker sampling frequency.
%         position_edges = the x positions for the 1D positions
% Cowen.

if Rows(POS) ~= Rows(LFPpos)
    error('POS and LFP must have the same number of rows.')
end

if nargin < 5
    bands = [];
end

OC = zeros(Rows(RANGES), n_place_bins, n_place_bins);
FF = zeros(Rows(RANGES), n_place_bins, n_place_bins, Cols(LFPpos));
SD = zeros(Rows(RANGES), n_place_bins, n_place_bins, Cols(LFPpos));


for iT = 1:Rows(RANGES)
    POS_tmp = Restrict(POS,RANGES(iT,:)); % This could be dangerous - it will limit the range.
    LFPpos_tmp = Restrict([POS(:,1) LFPpos],RANGES(iT,:));
   
    [MN,SDtmp,OCtmp,position_edges] = Frequency_fields(POS_tmp,LFPpos_tmp(:,2:end),n_place_bins);
    
    OC(iT,:,:) = OCtmp;
    for iBand = 1:Cols(LFPpos)
        FF(iT,:,:,iBand) = MN{iBand};
        SD(iT,:,:,iBand) = SDtmp{iBand};
    end
    fprintf('x')
end

if ~isempty(bands)
    % Plot the data.
    FF(isnan(FF)) = 0;
    kk= ceil(n_place_bins/30);
    K = hanning(kk)*hanning(kk)'./sum(sum( hanning(kk)*hanning(kk)'));
    for iBand = 1:Cols(LFPpos)
        subplot(Cols(LFPpos)/2,2,iBand)
        S = squeeze(sum(OC>0.001,1));
        LOW_OC_IX = S<3;
        MN = squeeze(nanmean(FF(:,:,:,iBand),1));
        %BADIX = S<4 | isnan(MN); % Get rid of points that the animal only visitied on <=3 trials.
        BADIX = MN==0 | isnan(MN) | LOW_OC_IX; % Get rid of points that the animal only visitied on <=3 trials.
        MN(BADIX) = 0;
        MNc = convn(MN,K,'same');
        MNc = Smooth_matrix(MNc,n_place_bins*2);
        MNc(abs(MNc)<0.0001) = nan;

        %subplot(1,2,1)
        imagesc( MNc')
        colormap(jet2)
        %contourf(MN',10)
        axis xy
        if iscell(bands)
            title(bands{iBand})
        elseif ~isempty(bands)
            title(num2str(bands(iBand,:)))
        else
            title(num2str(iBand))            
        end
    end
    %equalize_axes
end
