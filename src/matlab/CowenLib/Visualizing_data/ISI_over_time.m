function h = ISI_over_time(t)
% Plots the ISI over time. IT's like an instantaneouls firing rate (no binning).
% INPUT: a series of timestamps.
% OUTPUT: A gorgeous plot.
t = t(:)';
d = diff(t);
%d = max(d) - d;
%h = line([S(1:(end-1))';S(2:end)'],[d';d'])
x = [t(1:end-1);t(1:end-1);t(2:end);t(2:end)];
y = [zeros(1,length(d));d;d;zeros(1,length(d))];
h = patch(x,y,'r')
set(h,'LineStyle','.')
axis tight
ylabel('ISI')
xlabel('timstamp')
title('ISI Over Time')
