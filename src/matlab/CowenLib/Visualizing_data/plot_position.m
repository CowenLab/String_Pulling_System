function  plot_position(POS, colors, markersize, linestyle)
% Plots position from a standard 3 col matrix of time, x, y.
% The colors allows you to call this routine repeatedly to overlay results
% on top of the previous map - good for checking position following filtering.
% OR overlaying spikes on top of position
%
% Cowen 2010
fs = 12;

if nargin < 2
    colors ={[0 0 0 ] [.2 .2 .9]};
end

if nargin < 3
    markersize = 4.5;
end

if nargin < 4
    linestyle = '.-';
end

subplot(2,2,1:2)
plot(POS(1:3:end,1)/1e6/60,POS(1:3:end,2),linestyle,'MarkerSize',markersize,'Color',colors{1})
hold on
plot(POS(1:3:end,1)/1e6/60,POS(1:3:end,3),linestyle,'MarkerSize',markersize,'Color',colors{2})
axis tight
xlabel('time (min)','FontSize',fs)
set(gca,'FontSize',fs)
subplot(2,2,3)
plot(POS(1:3:end,2),POS(1:3:end,3),linestyle,'MarkerSize',markersize,'Color',colors{1})
hold on
axis tight
xlabel('x','FontSize',fs)
xlabel('y','FontSize',fs)
set(gca,'FontSize',fs)

%%
if (size(POS,2) >=5)
    subplot(2,2,4)
    plot(POS(1:3:end,4),POS(1:3:end,5),linestyle,'MarkerSize',markersize,'Color',colors{1})
    hold on
    axis tight
    xlabel('x','FontSize',fs)
    xlabel('y','FontSize',fs)
    set(gca,'FontSize',fs)
    
end
