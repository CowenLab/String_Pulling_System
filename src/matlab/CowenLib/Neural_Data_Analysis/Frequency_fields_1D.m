function [MN,SD,OC,x_axis] = Frequency_fields_1D(POS,LFPpos,n_place_bins,bands)
%function [MN,SD,OC,bin_edges] = Frequency_fields_1D(POS,LFPpos,n_place_bins,bands)
%
% Place field but for frequency bands - or any continuous data (e.g. EMG)
%
% INPUT: POSITION: time, x
%        LFP: Each col is a filtered lfp signal (each col is a frequency
%          band). This must be ALIGNED with the POS data so it's the same
%          number of rows as the position data.
%        n_place_bins = resolution of the position plotting.
%        band_labels (optional) - for plotting.
%
% OUTPUT: MN mean value of LFPpos at each location
%         SD std of LFPpos at each location
%         OC occupancy (count of times each spot was visited) - convert to
%            seconds by dividing by tracker sampling frequency.
%         position_edges = the x positions for the 1D positions
% Cowen.

% % How to make PFs using frequency fields (for a check)
% TSr = Restrict(TS,TRIAL_START_END(1)/100-1e4,TRIAL_START_END(end)/100-1e4);
% [STM r] = bin_ts_array(TSr,100); % 10000 would be 1 second bin size, 100 is 10msec.
% r = mean(r,2);
% STMr = decimate_matrix(STM,3); % lowpass and resample at a rate similar to the position sampling rate (30fps or 33 msec/frame)
% newr = linspace(r(1),r(end),Rows(STMr));
% % Interpolate the STM to the timestamps in the position data
% STMri = interp1_matrix(newr,STMr,PT.t/100,'linear');
% [PF2] = Frequency_Fields_1D_by_trial([PT.t PT.TPOS],STMri(:,iCell),nbins,TRIAL_START_END);


%%
if Rows(POS) ~= Rows(LFPpos)
    error('POS and LFP must have the same number of rows.')
end

if nargin < 4
    bands = [];
end

% The user can either specify the number of bins OR pass in a vector of
% edges.
if length(n_place_bins) == 1
    bin_edges = linspace(min(POS(:,2)),max(POS(:,2)) + 0.000001, n_place_bins+1);
    % We need to add just a tiny amount to the end as the histc for bin
    % edges will do a less than (<) for the higher edge. (EDGES(k) <= X(i)
    % < EDGES(k+1))
    % histc does somthing wierd - the last value of edges returns the count
    % of bins that match exactly the last bin. This is dumb, but to deal
    % with it, I will remove the last bin

else
    bin_edges = n_place_bins;
end
%pos_sFreq = 1/(median(diff(POS(:,1)))/1e6); % Assumptions made here.

% We need to add just a tiny amount to the end as the histc for bin
% edges will doa less than (<) for the higher edge. (EDGES(k) <= X(i)
    % < EDGES(k+1))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OC = zeros(length(bin_edges)-1,1);
MN = zeros(length(bin_edges)-1, Cols(LFPpos))*nan;
SD = zeros(length(bin_edges)-1, Cols(LFPpos))*nan;

%%  Seems like there must be a way to optimize this.
% Wait, can't I just sort POS and reindex LFPPOS - can't surf or mesh do
% this? There are clever ways to do this - not now though.
% old 

for ixB = 1:(length(bin_edges)-1)
    IX = POS(:,2) >= bin_edges(ixB) & POS(:,2) < bin_edges(ixB+1);
    if any(IX)
        for iBand = 1:Cols(LFPpos)
            v = LFPpos(IX,iBand);            %[m,ix ] = max(v); % Get rid of the max value - gets rid of outliers.
            %v(ix) = nan;
            MN(ixB,iBand) = nanmean(v);
            SD(ixB,iBand) = nanstd (v);
            if iBand == 1
                OC(ixB) = sum(IX);
            end
        end
    end
end

x_axis = bin_edges(1:(end-1)); % remember that xb are the bin edges so it will be one greater than the number of cols.


if 0 
tic
[sPOS,IX]= sort(POS); % actually, this could be done before this is called.
sLFPpos = LFPpos(IX,:);
start_ix = 1;
for ixB = 1:(length(bin_edges)-1)
    IX = sPOS(:,2) >= bin_edges(ixB) & sPOS(:,2) < bin_edges(ixB+1);
    if any(IX)
        for iBand = 1:Cols(LFPpos)
            v = LFPpos(IX,iBand);
            %[m,ix ] = max(v); % Get rid of the max value - gets rid of outliers.
            %v(ix) = nan;
            MN(ixB,iBand) = nanmean(v);
            SD(ixB,iBand) = nanstd (v);
            if iBand == 1
                OC(ixB) = sum(IX);
            end
        end
    end
end
toc
end
%pos_sFreq = 1e6/median(diff(POS(:,1)));
% BIG QUESTION: How do we properly normalize by occupancy? Simple
% division does not work in this case. I guess I could regress
% frequency by occupancy - look for any correlation (e.g. increased
% occupancy, increased frequency in 7hz) and then create maps based on
% the residuals of this regression. Do I really need to do this for
% frequency domain information? Occupancy sums.
%
%% % PLot

if nargout == 0 || ~isempty(bands)
    for iBand = 1:Cols(LFPpos)
        subplot((Cols(LFPpos)+1)/2,2,iBand)
        SE = real(SD(:,iBand)./(sqrt(OC-1)+eps));
        plot_confidence_intervals(x_axis,MN(:,iBand),[MN(:,iBand) + SE MN(:,iBand) - SE]' );
        title([num2str(bands(iBand,:)) ' SEM'])
    end
    equalize_axes
    %
    % EXAMINE CORRELATION OF OCCUPANCY WITH VALUES: 
    % for ii = 1:length(MN);figure;plot(OC,MN{ii},'.');lsline;end
end

if nargout == 4
    position_edges.x = bin_edges;
end
