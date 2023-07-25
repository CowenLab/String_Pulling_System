function [PF,TC,OCC,AXIS] = Plot_placefield_by_trial(TS,POS,RANGES,n_place_bins,smooth_factor,plot_it)
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

if nargin < 6 || nargout == 0
    plot_it = 1;
end

if nargin < 5
    smooth_factor = []; % NOTE: Numbers above 100 lead to artifactual emphasis of high occupancy locations. Perhaps this is due to some small offset in spike and positoin timing.
end

if nargin < 4
    n_place_bins = 30; 
end
% Restrict spikes

% Restrict position
IX = POS(:,1)>=min(RANGES(:)) & POS(:,1)<max(RANGES(:)) ;
POS = POS(IX,:);
mxPOS = max(POS(:,2:3));
mnPOS = min(POS(:,2:3));
min_max_X = [mnPOS(1) mxPOS(1)];
min_max_Y = [mnPOS(2) mxPOS(2)];
%%
PF = zeros(Rows(RANGES),n_place_bins,n_place_bins)*nan;
TC = zeros(Rows(RANGES),n_place_bins,n_place_bins)*nan;
OCC = zeros(Rows(RANGES),n_place_bins,n_place_bins)*nan;
for iT = 1:Rows(RANGES)
    TSR = Restrict(TS,RANGES(iT,:));
    IX = POS(:,1)>=RANGES(iT,1) & POS(:,1)<RANGES(iT,2) ;
    POSR = POS(IX,:);
    % insert the max and min position onto the data so that the binning for
    % each trial is the same.
    POSR = [0 mxPOS;1 mnPOS;POSR];
    %[pf tc oc]  = Plot_placefield(TSR,POSR,[],n_place_bins,smooth_factor,0);
    [tc,oc,pf] = Ratemap(POSR,TSR,n_place_bins, n_place_bins, min_max_X, min_max_Y);
    if any(isnan(pf(:)))
       error('nan')
    end
    %IX = oc==0;
    %pf(IX) = nan;
    %tc(IX) = nan;
    % oc(IX) = nan; % Occupancy CAN NOT BE A NAN BECAUSE ZERO DOES MEAN
    % SOMEHTING: MEANS HE NEVER VISITED THAT LOCATION - important for
    % averaging across trials.
    
    if ~isempty(smooth_factor)
        S = hanning(smooth_factor)*hanning(smooth_factor)';
        %S = S/sum(S(:));
        pf = conv2(pf+eps,S,'same');
    end
    
    PF(iT,:,:) = pf;
    TC(iT,:,:) = tc;
    OCC(iT,:,:) = oc;
end
% 
% OCCsec = OCC*(1/30); % Converts OCC to seconds
% 
% PFrate = nansum(TC,1)./nansum(OCCsec,1);
% 
%%
if nargout > 3 || plot_it
    AXIS.x = linspace(min(POS(:,2)),max(POS(:,2)),n_place_bins);
    AXIS.y = linspace(min(POS(:,3)),max(POS(:,3)),n_place_bins);
end

if plot_it
    
    S = squeeze(sum(OCC>0.001,1));
    BADIX = S<4; % Get rid of points that the animal only visitied on <=3 trials.
    MN = squeeze(nanmean(PF,1));
    %SD = squeeze(nanstd(PF,1));
    MN(BADIX) = 0;
    %SD(BADIX) = nan;
    %MNc = conv_filter(MN,hanning(2)*hanning(2)');
    %subplot(1,2,1)
    imagesc( AXIS.x,  AXIS.y, MN')
    %contourf(MN',10)
    axis xy   

%     MS = Smooth_matrix(MN,n_place_bins*2,n_place_bins*2);
%     subplot(1,2,2)
%     imagesc(MS)
%     axis xy   
    %pubify_figure_axis();
end

