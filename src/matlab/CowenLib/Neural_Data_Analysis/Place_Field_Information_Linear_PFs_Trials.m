function [O, V] = Place_Field_Information_Linear_PFs_Trials(x_dim, V, estimated_centers,filter_it,fld_loc_thresh_xdim, perc_peak)
% Given a n Trial by n Location matrix and a place field
% (e.g., after determining the place field bounds and only sending the
% cleaned up place field)
% return the following information...
%
% SHOULD TIS ASSUME animal is moving
%
% Phase locking of spikes to theta
% Phase precession
% 
% Mean PF.
% Portion of responding trials.
% Triai-by-trial measure of expansion (regression slope, center of mass on
% last -minus first trials.
%

%
% Cowen 2011
if nargin < 4 || isempty(filter_it)
    filter_it = true;
end
if nargin < 5 || isempty(fld_loc_thresh_xdim)
    fld_loc_thresh_xdim = inf;
end
if nargin < 6
    perc_peak = [];
end

if sum(V) ==0
    O = []; V = [];
    return
end

if any(sort(estimated_centers) ~= estimated_centers)
    error('Estimated centers must be in ascending order')
end
perc_of_pk_ht = 0.3333;
% GET RID OF CRAP DATA....

IX = estimated_centers > max(x_dim);
estimated_centers(IX) = [];
IX = estimated_centers < min(x_dim);
estimated_centers(IX) = [];
% cutoff = .15*max(V); % peaks smaller than this are ignored.
cutoff = 1; % peaks smaller than this are ignored.
%% 
V = V(:)';
Vo = V;
if filter_it
    % The filtering will depend on the choice of binning - so it really
    % should be done before it is passed into this function.
    %
    %V = conv_filter(V,hanning(5)/sum(hanning(5)));
    V = sgolayfilt( V,3,7); % Add some curvature to eliminaet the situation where you have 2 identical points next to each other (hence a diff of zero).
    V(V>0) = V(V>0) - rand(size(V(V>0)))/10000; % again, to ensure that no 2 adjacent peak points are absolutely identical. 

    %V = conv_filter( V,hanning(5)/sum(hanning(5)))'; % Add some curvature to eliminaet the situation where you have 2 identical points next to each other (hence a diff of zero).
    V(V<0) = 0;
    V(1:5) = Vo(1:5);
    V((end-5):end) = Vo((end-5):end);
end
%Ve = envelope(V);

de1 = [diff(V) 0];   % backward derivative
de2 = [0 diff(V)];   % forward derivative
%finding peaks
% PeaksIdx    = find(de1 < 0 & de2 > 0);
[mx,PeaksIdx] = findpeaks(V);
if isempty(PeaksIdx)
    [mx,PeaksIdx]= nanmax(V);
end
% TroughsIdx  = find(de1 > 0 & de2 < 0);
TroughsOrZeroIdx  = find((de1 > 0 & de2 < 0) | V == 0);
if ~isempty(perc_peak)
    th = max(V) * perc_peak;
%     BIX = V(TroughsIdx) < th;
%     TroughsIdx(BIX) = [];
     BIX = V(TroughsOrZeroIdx) > th;
     TroughsOrZeroIdx(BIX) = [];
end


if sum(V(PeaksIdx) > cutoff) ==0
    [~,ix] = max(mx);
    PeaksIdx = PeaksIdx(ix);
else
    PeaksIdx(V(PeaksIdx) < cutoff) = [];
end
% if isempty(PeaksIdx)
%     return
% end
%lowpt = median(V(TroughsIdx));
lowpt = prctile(V,15);

O.COMs = zeros(size(estimated_centers));
O.Peak_heights = zeros(size(estimated_centers));
O.Peak_location = zeros(size(estimated_centers));
O.Outside_Field_Peak_Percent = zeros(size(estimated_centers));

for iCtr = 1:length(estimated_centers)
    ix = find(x_dim > estimated_centers(iCtr),1,'first');
    % Find the closest peak to this index.
    tmp = Closest(PeaksIdx, ix);
    pkix = PeaksIdx(tmp);
    
    tmp = find(TroughsOrZeroIdx<(pkix-3),1,'last');
    
    if isempty(tmp)
        lowix = 1;
    else
        lowix = TroughsOrZeroIdx(tmp);
    end
    
    tmp = find(TroughsOrZeroIdx>(pkix + 3),1,'first');
    
    if isempty(tmp)
        highix = length(V);
    else
        highix = TroughsOrZeroIdx(tmp);
    end
    O.Peak_heights(iCtr) = V(pkix);
    O.Peak_location(iCtr) = x_dim(pkix);
    O.Peak_ix(iCtr) = pkix;
    
    O.Field_extent_troughs_ix(iCtr,:) = [lowix highix];
    O.Field_extent_troughs(iCtr,:) = [x_dim(lowix) x_dim(highix)];

    out_ix = setdiff(1:length(x_dim),lowix:highix);
    if isempty(out_ix)
        O.Outside_Field_Peak_Percent(iCtr) = 100 ;
    else
        mx_out = max(V(out_ix));
        O.Outside_Field_Peak_Percent(iCtr) = 100 * (mx_out/V(pkix));
    end
    if x_dim(lowix) > estimated_centers(iCtr) || abs(O.Peak_location(iCtr) - estimated_centers(iCtr)) > fld_loc_thresh_xdim 
        x_dim(lowix) 
        estimated_centers(iCtr) 
        
        O.Peak_heights(iCtr) = nan;
        O.Peak_location(iCtr) = nan;
        O.Peak_ix(iCtr) = nan;
        
        O.Field_extent_troughs_ix(iCtr,:) = [nan nan];
        O.Field_extent_troughs(iCtr,:) = [nan nan];
        
    end
    % low bound Use the 20% rule.
    
    th = (O.Peak_heights(iCtr)-lowpt) *perc_of_pk_ht + lowpt;
    lowix = find(V(1:pkix)<th,1,'last');
    
    if isempty(lowix)
        lowix = 1;
    end
    
    highix = find(V(pkix:end)<th,1,'first') + pkix-1;
    if isempty(highix)
        highix = length(V);
    end
    
    if x_dim(lowix) > estimated_centers(iCtr) 
        O.Field_extent_perc_pk_ix(iCtr,:) = [nan nan];
        O.Field_extent_perc_pk(iCtr,:) = [nan nan];
        O.COMs(iCtr) = nan;
        O.COMs_ix(iCtr) = nan;
    else
        if lowix < O.Field_extent_troughs_ix(iCtr,1)
           lowix = O.Field_extent_troughs_ix(iCtr,1);
        end
        if highix > O.Field_extent_troughs_ix(iCtr,2)
           highix = O.Field_extent_troughs_ix(iCtr,2);
        end
        O.Field_extent_perc_pk_ix(iCtr,:) = [lowix highix];
        O.Field_extent_perc_pk(iCtr,:) = [x_dim(lowix) x_dim(highix)];
        
        [O.COMs(iCtr), O.COMs_ix(iCtr)]= Center_of_mass(V(lowix:highix),x_dim(lowix:highix));
        O.COMs_ix(iCtr) = O.COMs_ix(iCtr) + lowix - 1; % Add the offsett.
    end
    
    % Clean up data that's unreasonable...
    if abs(O.COMs(iCtr) - estimated_centers(iCtr)) > fld_loc_thresh_xdim 
        O.Field_extent_perc_pk_ix(iCtr,:) = [nan nan];
        O.Field_extent_perc_pk(iCtr,:) = [nan nan];
        O.COMs(iCtr) = nan;
        O.COMs_ix(iCtr) = nan;
    end
    
    %
end

if nargout == 0 
%     x_dim = ~isnan(x_dim);
    plot(x_dim, Vo,'k')
    
    hold on
    plot(x_dim, V,'r')
    plot(estimated_centers,O.Peak_heights,'mo')
    plot(O.Peak_location,O.Peak_heights,'r*')
    plot(O.COMs,O.Peak_heights,'ks')
    plot(O.Field_extent_troughs(:,1),O.Peak_heights,'g>')
    plot(O.Field_extent_troughs(:,2),O.Peak_heights,'g<')
    plot(O.Field_extent_perc_pk(:,1),O.Peak_heights*.9,'c>')
    plot(O.Field_extent_perc_pk(:,2),O.Peak_heights*.9,'c<')
    a = axis;
    plot(a(1:2),[lowpt lowpt],'r:')
end