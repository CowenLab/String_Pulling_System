function [phase_position, ix ] = rescale_phase_by_position_data(phase_position)
%function [phase_position, ix ] = rescale_phase_by_position_data(phase_position)
% Find the region of interest in the phase-position plot.
% INPUT: 2 col matrix - 1st is phase data (degrees), second is position.
% OUTPUT: resecaled data
figure
subplot(2,1,1)
hist(phase_position(:,2),300)
axis tight
subplot(2,1,2)
plot(phase_position(:,2),phase_position(:,1),'.','MarkerSize',1)
title('Press space to select a region')
axis tight
pause
[x,y]=ginput(2);
goodix = find(phase_position(:,2) > min(x) & phase_position(:,2) < max(x));
phase_position = phase_position(goodix,:);
title('NOW SELECT THE TOP')
[x,y]=ginput(1);
ix = find(phase_position(:,1) > y);
% Shift and align.
phase_position(ix,1) = phase_position(ix,1) - 360;
phase_position(:,1)  = phase_position(:,1) + 360 - y;
plot(phase_position(:,2),phase_position(:,1),'.','MarkerSize',1)
axis tight
subplot(2,1,1)
hist(phase_position(:,2),300)
axis tight
