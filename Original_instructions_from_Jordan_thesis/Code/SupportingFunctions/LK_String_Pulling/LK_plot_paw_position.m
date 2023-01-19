function p = LK_plot_paw_position(PAW,GIX,GIXl,GIXr,good_string_pull_intervals_uSec)
%% INPUT: PAW = 7 column table with xy of paw per unit time.
clrs = lines(12);
% [GIX,GIXl,GIXr,INF] = LK_process_paw_data(PAW, good_string_pull_intervals_uSec);

figure
plot(PAW.Time_uSec(GIXr), PAW.Right_x(GIXr),'.','Markersize',1)
hold on
plot(PAW.Time_uSec(GIXr), PAW.Right_y(GIXr),'.','Markersize',1)
plot(PAW.Time_uSec(GIXl), PAW.Left_x(GIXl),'.','Markersize',1)
plot(PAW.Time_uSec(GIXl), PAW.Left_y(GIXl),'.','Markersize',1)

% figure
% comet(PAW.Left_x(GIXl), PAW.Left_y(GIXl));

figure
plot(PAW.Right_x(GIX), PAW.Right_y(GIX),'b.','Markersize',1)
hold on
plot(PAW.Left_x(GIX), PAW.Left_y(GIX),'g.','Markersize',1)
% plot(PAW.Nose_x(GIX), PAW.Nose_y(GIX),'r.','Markersize',1)

%%%%%%%%%%%%
dx = diff(PAW.Right_x);
dy = diff(PAW.Right_y);
dx(end+1) = 0;
dy(end+1) = 0;

%%%%%%%%%%
nbins = 100;
[RightXY,XedgesR,YedgesR] = histcounts2(PAW.Right_x(GIXr),PAW.Right_y(GIXr),nbins);
[LeftXY,XedgesL,YedgesL] = histcounts2(PAW.Left_x(GIXl),PAW.Left_y(GIXl),nbins);
RightXY = RightXY';
LeftXY = LeftXY';
RightXYc = conv2(RightXY,hanning(10)*hanning(10)');
LeftXYc = conv2(LeftXY,hanning(10)*hanning(10)');

figure
subplot(1,2,1)
imagesc(XedgesR(2:end),YedgesR(2:end),RightXYc)
axis xy
subplot(1,2,2)
imagesc(XedgesL(2:end),YedgesL(2:end),LeftXYc)
axis xy

[xq,yq] = meshgrid(XedgesR,YedgesR);
vq = griddata(PAW.Right_x(GIXr),PAW.Right_y(GIXr),PAW.Right_speed(GIXr),xq,yq);
aq = griddata(PAW.Right_x(GIXr),PAW.Right_y(GIXr),PAW.Right_acc(GIXr),xq,yq);

figure
mesh(xq,yq,vq)
hold on
plot3(PAW.Right_x(GIXr),PAW.Right_y(GIXr),PAW.Right_speed(GIXr),'o','MarkerSize',2)
title('Speed')
figure
mesh(xq,yq,aq)
hold on
plot3(PAW.Right_x(GIXr),PAW.Right_y(GIXr),PAW.Right_acc(GIXr),'o','MarkerSize',2)
title('Acceleration')

[xq,yq] = meshgrid(XedgesL,YedgesL);
vq = griddata(PAW.Left_x(GIXl),PAW.Left_y(GIXl),PAW.Left_speed(GIXl),xq,yq);
aq = griddata(PAW.Left_x(GIXl),PAW.Left_y(GIXl),PAW.Left_acc(GIXl),xq,yq);

figure
mesh(xq,yq,vq)
hold on
plot3(PAW.Left_x(GIXl),PAW.Left_y(GIXl),PAW.Left_speed(GIXl),'o','MarkerSize',2)
title('Speed')
figure
mesh(xq,yq,aq)
hold on
plot3(PAW.Left_x(GIXl),PAW.Left_y(GIXl),PAW.Left_acc(GIXl),'o','MarkerSize',2)
title('Acceleration')