function [hb ,he]= Error_bars(varargin)
%[e,m,err] =
%function Error_bars(varargin)
% Plot a bar graph of the matrices in varargin of their means and sem and stds.
% INPUT : varargin of vectors for calculating means and stds and sems on
%         assumes that all vargins only one column.
% OUTPUT: Bar graph with the SEM as a red error whisker.
%         reference to the handle of the error bars

% cowen
error_type = 'Sem';
plot_points = true;
count = 1;
% find commands and creat an argument cell array that just has the data.
for ii = 1:length(varargin)
    if ischar(varargin{ii})
        switch varargin{ii}
            case 'std'
                error_type = 'std';
            case 'nanstd'
                error_type = 'nanstd';
            case '1.95*std'
                error_type = '1.95*std';
            otherwise
                error('Incorrect error type')
        end
    else
        arg{count} = varargin{ii};
        count = count + 1;
    end
end
%%%%%% the real code %%%%%
if length(arg) == 1
    if iscell(arg{1})
        error('hmmm')
    else
        m   = nanmean(arg{1});
        sd  = nanstd(arg{1});
        eval(['err = ' error_type '(arg{1});']);
    end
else
    %m = zeros(size(arg{1},2),length(arg));
    %sd = zeros(size(arg{1},2),length(arg));
    %err = zeros(size(arg{1},2),length(arg));
    for ii = 1:length(arg)
        if isempty(arg{ii})
            arg{ii} = nan;
        end
        m(ii) = nanmean(arg{ii});
        sd(ii) = nanstd(arg{ii});
        eval(['err(ii) = ' error_type '(arg{ii});']);
        err(ii) = feval(error_type,arg{ii});
    end
end

hh = bar(m);
set(hh,'FaceColor',[.8 .8 .8])
hold on
if plot_points
    if nargin==1
        for ii = 1:Cols(arg{1})
            pts = arg{1}(:,ii);
            x = repmat(ii,length(pts),1);
            x = x + (rand(size(x))-.5)*.2;
            plot(x,pts,'o','MarkerSize',8,'MarkerFaceColor',[.2 .2 .2],'MarkerEdgeColor',[.5 .1 .5])
        end
    else
        for ii = 1:length(arg)
            pts = arg{ii};
            x = repmat(ii,length(pts),1);
            x = x + (rand(size(x))-.5)*.2;
            plot(x,pts,'o','MarkerSize',8,'MarkerFaceColor',[.2 .2 .2],'MarkerEdgeColor',[.5 .1 .5])
        end
    end
end

%errorbar(m,sd,'+')
if 1
    
    errorb(1:length(m),m,err,'barwidth',2); e = [];
else
    
    e = errorbar(m,err,'k','LineStyle','none');
end

hold on
% set(e,'LineWidth',2)
% set(gca,'FontSize',12)
%set(e,'MarkerSize',0.1)
%hold on
%plot(m,'+k')
%set(e(2),'MarkerSize',.1);
%set(e(2),'Color','b');
%hold off
pubify_figure_axis

if nargout > 0
    hb = hh;
    he = e;
end