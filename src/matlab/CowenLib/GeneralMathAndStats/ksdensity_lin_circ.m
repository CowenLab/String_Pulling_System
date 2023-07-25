function [KS, KSbig, new_yctrs_ph] = ksdensity_lin_circ(data_x_ph,xctrs_lin,yctrs_ph,bandwidth_params,phase_units)
% Performs a 2D KS density estimate on data where one dimension is linear
% (e.g., position) and another one is phase (e.g., circular phase data for
% phase precession analysis). Output is a KS density estimate for each
% phase.
%
% It is ASSUMED THAT PHASE ranges from 0 to 360 degrees (or 0 to 2pi
% radians if specified). The code then doubles the data by adding 360
% degrees to phase. The ks density is computed on this doubled data to get
% rid of edge effects near 0 and 360 degrees.
%
% Cowen 2018

if nargin < 5
    phase_units = 'degrees';
end
switch phase_units
    case 'degrees'
        data_x_ph = [data_x_ph; [data_x_ph(:,1) data_x_ph(:,2) + 360]];
        new_yctrs_ph = [yctrs_ph(:);yctrs_ph(:)+360];
    case 'radians'
        data_x_ph = [data_x_ph; [data_x_ph(:,1) data_x_ph(:,2) + 2*pi]];
        new_yctrs_ph = [yctrs_ph(:);yctrs_ph(:)+2*pi];
    otherwise
        error('wrong units')
        
end
ph_fix_ix = (length(yctrs_ph)+1): (length(yctrs_ph)+(round(length(yctrs_ph)/3)));

[x1,x2] = ndgrid(new_yctrs_ph,xctrs_lin);
f = mvksdensity(data_x_ph,[x2(:) x1(:)],'Bandwidth',bandwidth_params);
KSorig = reshape(f, Rows(x1),Cols(x1));
KSbig=KSorig;
KSbig(1:length(ph_fix_ix),:) = KSorig(ph_fix_ix,:); % this gets rid of the edge effect for phase information.
KS = KSbig(1:length(yctrs_ph),:); % cut out the 0 to 360 degree region again.

if nargout == 0
    figure
    subplot(1,2,1)
    imagesc(xctrs_lin,new_yctrs_ph, KSorig);axis xy
    
    subplot(1,2,2)
    imagesc(xctrs_lin,new_yctrs_ph, KSbig);axis xy
end
