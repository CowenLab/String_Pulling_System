function [PF,TC,Occ,AXIS,PFrate] = Plot_placefield(TS,POS,RANGES,n_place_bins,smooth_factor,plot_it)
% Plots placefields for different ranges of time
% INPUT:
% TS - timestamps (a vector) - Assumes its in uSec, 
% POS - 3 col matrix time x y - Assumes uSec assumes sampling
% 1/median(diff(TS)). (30hz is the usual)
%
% optional parameters:
% RANGES - 2 col matrix of start and end times - Assumes uSec.
% bin granularity
% degree of smoothing (empty if no smoothing)
% whether or not to plot the field.
%
% OUTPUT:
% place field, rate map, and occupancy.
% 
% Cowen(2009)
%
if nargin < 6 || nargout ==0
    plot_it = 1;
end

if nargin < 5
    smooth_factor = []; % A good smooth factor is: n_place_bins/10; or 30.
    %smooth_factor = n_place_bins/10;
end

if nargin < 4 || isempty(n_place_bins)
    n_place_bins = 80; % NOTE: Numbers above 100 lead to artifactual emphasis of high occupancy locations. Perhaps this is due to some small offset in spike and positoin timing.
end

if nargin < 3
    RANGES = [];
end

if ~isempty(RANGES)
    % Restrict POS
    %POS = Restrict(POS,RANGES);
    % Restrict spikes
    TS = Restrict(TS,RANGES);
end
%SPD = sum([0 0 ; abs(diff(POS(:,2:3)))],2);
%[SFx, SFy, SFs] = ScatterFields({TS/100}, tsd(POS(:,1)/100,POS(:,2)), tsd(POS(:,1)/100,POS(:,3)), tsd(POS(:,1)/100,SPD));
%D = [Range(SFx{1}) Data(SFx{1}) Data(SFy{1}) Data(SFs{1})]; 

%o = ndhist(D(:,2:4)', [n_place_bins;n_place_bins;100], min(D(:,2:4))', max(D(:,2:4))');
%o2 = ndhist([POS(:,2:3) SPD]', [n_place_bins;n_place_bins;100], min(D(:,2:4))', max(D(:,2:4))');

%OccS = sum(o2,3);
%[TC1,Occ1] = TuningCurves({TS/100}, [] ,tsd(POS(:,1)/100,POS(:,2)), n_place_bins, tsd(POS(:,1)/100,POS(:,3)), n_place_bins);
%PF = TC./(Occ+eps);

[TC,Occ,PF] = Ratemap([POS(:,1) POS(:,2:3)], TS, n_place_bins, n_place_bins);
%subplot(2,2,1);imagesc(TC1);colorbar;subplot(2,2,2);imagesc(TC);colorbar;
%subplot(2,2,3);imagesc(Occ1);colorbar;subplot(2,2,4);imagesc(Occ);colorbar;
% Old school placefield - very simple..
if ~isempty(smooth_factor)
    % New school smoothed place field
    S = hanning(smooth_factor)*hanning(smooth_factor)';
    %S = S/sum(S(:));
    PFs = conv2(TC./(Occ+eps),S);
    % normalze the range to be between the original rate (probably a better
    % way to do this.)
    v = standardize_range(PFs(:),[min(PF(:)) max(PF(:))]);
    PF = reshape(v,size(PFs));
end

if nargout > 3 || plot_it
    AXIS.x = linspace(min(POS(:,2)),max(POS(:,2)),n_place_bins);
    AXIS.y = linspace(min(POS(:,3)),max(POS(:,3)),n_place_bins);
end

if nargout > 4
    % multiply by sampling rate to get the rate at each position.
    sFreq_pos = 1e6/median(diff(POS(:,1)));
    PFrate = PF*sFreq_pos;
end

if plot_it
    imagesc(AXIS.x,AXIS.y,PF');
    axis xy
end