function [MN,SD,OC,position_edges] = Frequency_fields(POS,LFPpos,n_bins)
% function [MN,SD,OC] = Frequency_fields(POS,LFPpos,n_bins)
%
% Place field but for frequency bands - or any continuous data (e.g. EMG)
%
% INPUT: POSITION: time, x, y 
%        LFP: Each col is a filtered lfp signal (each col is a frequency
%          band). This must be ALIGNED with the POS data so it's the same
%          number of rows as the position data.
%        n_bins = resolution of the position plotting.
%
% OUTPUT: MN mean value of LFPpos at each location
%         SD std of LFPpos at each location
%         OC occupancy (amount of times each spot was visited) - convert to
%            seconds by dividing by tracker sampling frequency.
%         position_edges = the x and y positions for the 2D position
%         matrix.
%
% Cowen.
% I will have to make a 1D version of this as well.
%%
if Rows(POS) ~= Rows(LFPpos)
    error('POS and LFP must have the same number of rows.')
end

xb = linspace(min(POS(:,2)),max(POS(:,2)),n_bins);
yb = linspace(min(POS(:,3)),max(POS(:,3)),n_bins);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
OC = zeros(length(xb), length(yb));
for iBand = 1:Cols(LFPpos)
    MN{iBand} = zeros(length(xb), length(yb))*nan;
    SD{iBand} = zeros(length(xb), length(yb))*nan;
end

%%  Seems like there must be a way to optimize this.
for ixB = 1:(length(xb)-1)
    for iyB = 1:(length(yb)-1)
        IX = POS(:,2) >= xb(ixB) & POS(:,2) < xb(ixB+1) & POS(:,3) >= yb(iyB) & POS(:,3) < yb(iyB+1);
        if any(IX)
            for iBand = 1:Cols(LFPpos)
                v = LFPpos(IX,iBand);
                %[m,ix ] = max(v); % Get rid of the max value - gets rid of outliers.
                %v(ix) = nan;
                MN{iBand}(ixB,iyB) = nanmean(v);
                SD{iBand}(ixB,iyB) = nanstd (v);
                if iBand == 1
                    OC(ixB,iyB) = sum(IX);
                end
            end
        end
    end
    fprintf('.')
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

if nargout == 0 
    for iBand = 1:Cols(LFPpos)
        subplot(2,(Cols(LFPpos)+1)/2,iBand)
        imagesc(MN{iBand}');
        %w = hanning(3)./sum(hanning(3));
        %imagesc(smooth_matrix(conv2(MN{iBand},w*w'),300))
        axis xy
        caxis([-1 3])
    end
end

if nargout == 4
    position_edges.x = xb;
    position_edges.y = yb;
end
