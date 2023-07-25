function [dom angles_rad max_angle] = Rotate_time_phase_plot(XY, interval_rad, plot_it)
% function dom = rotate_time_phase_plot(XY, interval_rad, plot_it)
%
% Analysis that will rotate cells that are precessing, all the while,
% calculating the depth of modulation at the rotational angle.
% Cowen 2006
%
if nargin < 3
    plot_it = 0;
end
if interval_rad < 0
    interval_rad = 0.02;
end
angles_rad = (-pi/4):interval_rad:(pi/4);
dom = zeros(length(angles_rad),1);

if plot_it
    clf
    plot_stuff(XY)
end

for iA = 1:length(angles_rad)
    [Xr Yr] = rotateXY(XY(:,1), XY(:,2), angles_rad(iA));
    [k,x] = ksdensity(Xr);
    %    d = diff(k)>0 ;
    %find
    xdim = linspace(min(Xr)+0.0001,max(Xr),40);
    [hi] = histc(Xr,xdim);
    [mx,ix] = max(hi); % gets rid of outliers.
    hi(ix) = hi(ix+1);

    
    dom(iA) = nanmax(hi) - nanmin(hi); % Another would be the energy in the 7hz band.
    if plot_it
        plot_stuff([Xr Yr])
        title([ num2str(radians_to_degrees(angles_rad(iA))) ' ' num2str(dom(iA))])
        pause
    end
end

[mx,ix] = max(dom);
max_angle = angles_rad(ix);

if plot_it
    figure
    plot(angles_rad,dom)
    xlabel('angle')
    ylabel('depth of mod')
end

function plot_stuff(XY)
xdim = linspace(min(XY(:,1)),max(XY(:,1)),70);
subplot(4,1,1:3)
plot(XY(:,1),XY(:,2),'b.');
%ndh = ndhist(XY',[40; 40],min(XY),max(XY));

subplot(4,1,4)
cla
% [k,x]=ksdensity(XY(:,1));
% plot(x,k)

[hi] = histc(XY(:,1),xdim);
[mx,ix] = max(hi); % gets rid of outliers.
mx(ix) = hi(ix+1);
bar(xdim,hi)
hold on
plot(xdim,sgolayfilt(hi,3,7),'r')
return