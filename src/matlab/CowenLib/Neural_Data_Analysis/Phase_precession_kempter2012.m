function [cc,sl,offs] = Phase_precession_kempter2012(spike_time_pos_and_phase,ROBUST)
% function [cc,sl,offs] = Phase_precession_kempter2012(spike_time_pos_and_phase)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% From kempter 2012. NOTE: this is senstive to any spikes that are far from
% the place field center so restrict spikes to bounds of the place field.
%
% INPUT:
%  spike_time_pos_and_phase: a n spike x 3 col matrix of spike times,
%  location at the time, and phase at that time. Time is not really used
%  but useful for other diagnostics.
%
% OUTPUT:
%
% implementation of Kempter 2012 approach. See his J Neuro Methods paper. 
% (core code by Eric Reifenstein, 1-June-2016)
%
%  cowen 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2
    ROBUST = false;
end

if nargin == 0
    % Example for a circular-linear fit of a bivariate Gaussian
    % (by Eric Reifenstein, 1-June-2016)
    % generating data for position and theta phase from a bivariate Gaussian
    mu = [20,pi]; % vector of means
    sigma = [36,-5;-5,1.2]; % covariance matrix
    r = mvnrnd(mu,sigma,100); % draw 100 random samples
    pos = r(:,1); % position data, in cm
    phase = mod(r(:,2),2*pi); % theta phase, restricted to [0,2*pi[
    
    SPT = [[1:length(pos)]' pos phase];
    Phase_precession_kempter2012(SPT);
    return
end
if ROBUST
    n = ceil(Rows(spike_time_pos_and_phase)/1.5);
    nboot = 100;
    cc = nan(nboot,1);
    sl = nan(nboot,1);
    offs = nan(nboot,1);
    
    for ii = 1:100
        y = datasample(spike_time_pos_and_phase,n,1,'Replace',true);
        [cc(ii),sl(ii),offs(ii)] = Phase_precession_kempter2012(y,false);
    end
    cc = nanmedian(cc);
    sl = nanmedian(sl);
    offs = nanmedian(offs);
    if nargout == 0
        
        pos = spike_time_pos_and_phase(:,2); % position data, in cm
        phase = spike_time_pos_and_phase(:,3); % theta phase, restricted to [0,2*pi[
        x = (min(pos))-5:0.1:(max(pos)+5);

        pos = [pos;pos]; % double for plotting
        phase = [phase;phase + 2*pi]; % double for plotting
        
        figure
        plot(pos,180/pi * phase,'k.')
        hold on
        plot(x, 180/pi * (sl * x + offs) )
        xlabel('Position (cm)')
        ylabel('Phase (deg)')
        title('ROBUST')
        axis([0 inf 0 720])
    end
    return
end

pos = spike_time_pos_and_phase(:,2); % position data, in cm
phase = spike_time_pos_and_phase(:,3); % theta phase, restricted to [0,2*pi[

% slope and offset:
% objective function, see Kempter et al. (2012) for details
myfun1 = @(p) -sqrt((sum(cos(phase-(p(1)*pos)))/length(phase)).^2 + (sum(sin(phase-(p(1)*pos)))/length(phase)).^2);

% finding the optimal slope, note that we have to restrict the range of
% possible slopes (here: one theta cycle per field width)
sl = fminbnd(myfun1, -2*pi/(max(pos)-min(pos)), 2*pi/(max(pos)-min(pos)));

% calculate offset
offs = atan2(sum(sin(phase-sl*pos)),sum(cos(phase-sl*pos))) + 2*pi;
    
% circular-linear correlation:
pos_circ = mod(abs(sl)*pos, 2*pi); % circular variable derived from the position
phase_mean = mod(angle(sum(exp(i*phase))/length(phase)),2*pi); % circular mean of the theta phase
pos_circ_mean = mod(angle(sum(exp(i*pos_circ))/length(phase)),2*pi); % circular mean of the circular position variable

% calculating the correlation
cc = sum(sin(phase - phase_mean) .* sin(pos_circ - pos_circ_mean)) / sqrt( sum(sin(phase - phase_mean).^2) * sum(sin(pos_circ - pos_circ_mean).^2) );

if nargout == 0
    % plot the result, phases in deg
    x = (min(pos)-5):0.1:(max(pos)+5);

    pos = [pos;pos]; % double for plotting
    phase = [phase;phase + 2*pi]; % double for plotting
    
    figure
    plot(pos,180/pi * phase,'k.')
    hold on
    plot(x, 180/pi * (sl * x + offs) )
    xlabel('Position (cm)')
    ylabel('Phase (deg)')
    axis([0 inf 0 720])
    
    % text output
    fprintf('------------------------------------------------- \n')
    fprintf(sprintf('Slope:                         sl = %.1f deg/cm \n', 180/pi*sl))
    fprintf(sprintf('Offset at position x=0:      offs = %.1f deg \n', 180/pi*offs))
    fprintf(sprintf('Circular-linear correlation:   cc = %.3f \n', cc))
    fprintf('------------------------------------------------- \n')

end