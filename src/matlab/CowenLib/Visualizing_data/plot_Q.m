function h= plot_Q(T, dt_msec, intervals_ts, interval_names, colors, ytext)
%function h= plot_Q(T, dt_msec, intervals_ts, interval_names, colors)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% A standard plot of the Q matrix with sum of Q on the top.
%  events and epochs are labelled with colors.
%
% INPUT: cell array of spike times.
%        binsize msec
%        intervals_ts = a cell array of different intervals.%
%        interval_text = a cell array of text descriptors of each interval
%        colors are the colors to use to draw each interval.
% OUTPUT: the axis id's
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6 
    ytext = 1:length(T);
end
smooth_window_sec = 120; % Smooth over 1 minute.
smooth_bins = (smooth_window_sec*1000)/dt_msec;
if rem(smooth_bins,2) == 0
    % needs to be odd.
    smooth_bins = smooth_bins + 1;
end

if nargin < 5 | isempty(colors)
    colors = {'b' 'r' 'g' 'y' 'c' 'w' 'm' 'b' 'r' 'g' 'y' 'c' 'w' 'm' };
end
all_intervals = [];
if nargin < 3
    intervals_ts{1} = [Find_start(T) Find_end(T)] ;
end
if nargin < 4
    interval_names = [];
end

for ii = 1:length(intervals_ts)
    all_intervals = [all_intervals; intervals_ts{ii}];
end
all_intervals = sortrows(all_intervals);
if isempty(T)
    return
end

% Limit the intervals to the times when there are spikes
%sT = find_Start(T);
%eT = find_End(T);
%for ii =1:length(intervals_ts)
%end


b = []; g = []; r = []; all_rr = [];
[bQ,rQ] = bin_ts_array(T,binned([all_intervals(1) all_intervals(end)],dt_msec*10));
s = mean(bQ,2);
sz = mean(Z_Scores(bQ),2);
sr = standardize_range(mean(Z_Scores(bQ),2));
s = standardize_range(sgolayfilt(s,5,smooth_bins));
sz = standardize_range(sgolayfilt(sz,5,smooth_bins));
clf
h(1) = subplot(7,1,1);
plot(rQ(:,1)/1e4/60,s,'k')
hold on
plot(rQ(:,1)/1e4/60,sr,'r')
plot(rQ(:,1)/1e4/60,sz,'b')
axis tight;
xlabel([' Smoothed over ' num2str(smooth_window_sec) ' seconds '],'FontSize',8)
%for epID = 1:length(interval_names)
%    patch_intervals(intervals_ts{epID}/1e4/60,colors{epID},0.1);
%end
axis off
h(2)=subplot(7,1,2:7);
imagesc(rQ(:,1)/1e4/60, 1:Cols(b), standardize_range(bQ)')
%set(gca,'YTick',1:cols(b))
hold on
for epID = 1:length(interval_names) % Screwy order because i want rest at beginning and end.
    % plot behavior as a functio of epoch.
    x = binned(intervals_ts{epID},500);
    plot(x(:,1)/1e4/60,ones(rows(x),1)*.5, [colors{epID} '.'],'markersize',7)
end
% The legend covers up too much good stuff.
%l = legend(interval_names,'location','BestOutside');
%set(l,'Fontsize',6)
xlabel(['Minutes (dt = ' num2str(dt_msec) 'msec)'])
ylabel('Neuron')
set(gca,'YTick',1:cols(bQ))
set(gca,'YTickLabel',ytext)
set(gca,'FontSize',6)

%plot(rQ(:,1)/1e4/60,(s/max(s)) * length(SD.T)/4 ,'y')