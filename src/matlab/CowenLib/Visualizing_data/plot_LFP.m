function ypos = plot_LFP(L, sFreq_or_time, shift_f, Channels, event_markers, units)
% Plots the LFP data
% INPUT: L a nSample X nCHannel matrix
%        sFreq_or_time - either the sFreq or the timestamps for each point.
%        shift_f = the amount to shift each plot on the y axis.
%        Channels = y labels
% Cowen 2011
% cla
ypos = [];
L = double(L);
xlabel_txt = '';
HORIZ_AT_ZERO = false;
if nargin < 2 || isempty(sFreq_or_time)
    disp('No sampling rate or timestmaps specified. Assuming 1Hz')
    xlabel_txt = 'record number';
    sFreq_or_time = 1:size(L,1);
end

if nargin < 3 || isempty(shift_f)
    shift_f = range(L(:));
end
if nargin < 4 || isempty(Channels)
    Channels = 1:size(L,2);
end
if nargin < 5
    event_markers = [];
end
if nargin < 6 || isempty(units)
    units = 'sec';
end

C = lines(size(L,2));
% C = jet(size(L,2));
if length(sFreq_or_time) == 1
    xlabel_txt = units; % Sampling rate passed in.

    x_axis = (1:size(L,1)) / sFreq_or_time;
    switch units
        case 'sec'
        case 'min'
            x_axis = x_axis/60;
        case 'hours'
            x_axis = x_axis/3600;
    end
else
    x_axis = sFreq_or_time;
end
%%
line(x_axis,L(:,1),'Color',C(1,:))
hold on
if HORIZ_AT_ZERO
    line(x_axis,zeros(size(L(:,1))),'Color','r')
end

%rng_cnt = double(range(L(:,1)));
%yrng(1) = rng_cnt;
ypos = zeros(1,size(L,2));
for iCh = 2:size(L,2)
    shft = (iCh-1)*shift_f;
    line(x_axis,L(:,iCh)+shft,'Color',C(iCh,:))
    if HORIZ_AT_ZERO
        line(x_axis,zeros(size(L(:,iCh)))+shft,'Color','r')
    end
    ypos(iCh) = shft;

    % rng_cnt = rng_cnt + double(range(L(:,iCh)));
    % yrng(iCh) = rng_cnt + eps;
    %    plot(x_axis,N(:,iCh)+(iCh-1)*shift_f,'.-','Color',C(iCh,:))
end

if iscell(Channels)
    for iCh = 1:size(L,2)
        %text(x_axis(3),ypos(iCh),Channels{iCh},'FontSize',10,'Color',C(iCh,:),'BackgroundColor','w')
        text(x_axis(end),ypos(iCh),Channels{iCh},'FontSize',10,'Color',C(iCh,:),'BackgroundColor','w')
    end
else
    for iCh = 1:size(L,2)
        %text(x_axis(3),ypos(iCh),num2str(Channels(iCh)),'FontSize',12,'Color',C(iCh,:),'BackgroundColor','w')
        text(x_axis(end),ypos(iCh),num2str(Channels(iCh)),'FontSize',12,'Color',C(iCh,:),'BackgroundColor','w')
    end
end

set(gcf,'Color',[.5 .5 .5])
axis tight
%set(gca,'XTick',yrng)
xlabel(xlabel_txt)

if ~isempty(event_markers)
    plot_markers_simple(event_markers)
end

