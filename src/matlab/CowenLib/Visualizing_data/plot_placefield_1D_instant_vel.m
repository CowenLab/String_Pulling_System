function [PF,bin_edges] = plot_placefield_1D_instant_vel(TS,POS,VEL,bin_edges)
% I don't know if this would ever work to actually give you a measure of a
% placefield? You just get an instant rate at a specific point. You could
% perhaps do something clever and do a sliding window over these points
% with the rule that if there are these points within the window, then the
% instant rate is the mean of these points. If no points in the window,
% then the mean is zero. This might actually work.
%
% AT THE MOMENT THIS DOES NOT WORK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
%
% Plots 1 dimensional placefields for different ranges of time
% INPUT:
% TS - timestamps (a vector) - Assumes its in uSec
% RANGES - 2 col matrix of start and end times - Assumes uSec.
% bin granularity
% degree of smoothing (empty if no smoothing)
% whether or not to plot the field.
%
% OUTPUT:
% place field, rate map, and occupancy.
%
%
% EXAMPLE:
%    bin_edges = linspace(min(PT.Tix),max(PT.Tix),150);
%    [PF] = plot_placefield_1D_instant_vel(TS{iCell}*100,[PT.t PT.Tix],VEL,bin_edges);
%    plot(bin_edges(1:(end-1)),PF)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen(2009)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Spikes at each position
[SFx] = ScatterFields({TS/100}, tsd(POS(:,1)/100, POS(:,2)));
[SFv] = ScatterFields({TS/100}, tsd(VEL(:,1)/100, VEL(:,2)));


X = Data(SFx{1});
%T = Range(SFv{1});
V = Data(SFv{1});
% Sort by position
[X,IX] = sortrows(X);
V = V(IX);

% Go through segments of position, look for any SFv values at this point.
% If there are any, average them and this becomes the rate at this bin. Do
% I average or do i sum? Maybe I need to sum them up?
PF = zeros(1,length(bin_edges)-1);
for ii =2:length(bin_edges)
    ix = find(X >= bin_edges(ii-1) &  X < bin_edges(ii));
    if ~isempty(ix)
        PF(ii-1) = mean(V(ix)); % mean or sum??
    end
end
%plot(bin_edges(1:(end-1),PF)


if 0
    % For each point in X, find the mean velocity at that point - that is the
    % firing rate???
    u = unique(X);
    v = zeros(length(u),1);
    for ii = 1:length(u)
        v(ii) = mean(V(X==u(ii)));
    end
    % Now we have the average normalized rate at

    %PF = [u(:) sgolayfilt(v,3,51)];
    PF = [u(:) v(:)];

    clf
    plot(u,v,'.-')
    hold on
    %plot(u,sgolayfilt(v,3,51),'r.-')
    plot(u,v,'r.-')
end


