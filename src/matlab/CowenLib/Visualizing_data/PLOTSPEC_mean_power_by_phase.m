function [mn,se,bin_centers,mns,ses] = PLOTSPEC_mean_power_by_phase(power,phase,bin_centers,nshuffle,plot_it)
% Create a plot of the mean power per phase. Also provide a shuffle control
% if requested.
mns = []; ses = [];
phase = phase(:);
conv_to_ang = false;
avg_over_repeated = true;

if nargin < 3 || isempty(bin_centers)
    bin_centers = unique(phase);
end
if nargin < 4
    nshuffle = 100;
end
if nargin < 5
    plot_it = true;
end

if avg_over_repeated
    ph = [];po = [];
    dix = find(abs([1;diff(phase)])>0);
    for i = 2:length(dix)
        po(i) = mean(power(dix(i-1):dix(i)-1));
        ph(i) = phase(dix(i));
    end
    phase = ph;
    power = po;
end

if conv_to_ang
    phase = rad2ang(phase);
    bin_centers = rad2ang(bin_centers);
end
[mn,se] = grpstats(power,phase,{'mean' 'Sem'});

if ~isempty(nshuffle)
    mns = zeros(nshuffle,length(bin_centers));
    ses = zeros(nshuffle,length(bin_centers));
    for i = 1:nshuffle
        [mns(i,:),ses(i,:)] = grpstats(power(randperm(length(power))),phase,{'mean' 'Sem'});
    end
end
if plot_it
    plot(bin_centers,mn,'LineWidth',4,'Color','k')
    hold on
    plot(bin_centers,mn+se,'LineWidth',1,'Color','k')
    plot(bin_centers,mn-se,'LineWidth',1,'Color','k')
    axis tight
    xlabel('Phase')
    pubify_figure_axis
    
    if ~isempty(nshuffle)
        plot(bin_centers,mean(mns),'LineWidth',4,'Color',[.2 .2 .2])
        plot(bin_centers,mean(mns) + std(mns),'LineWidth',1,'Color',[.8 .8 .2])
        plot(bin_centers,mean(mns) - std(mns),'LineWidth',1,'Color',[.8 .8 .2])
    end
end