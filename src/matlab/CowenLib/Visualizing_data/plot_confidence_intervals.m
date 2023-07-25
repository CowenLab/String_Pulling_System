function hout = plot_confidence_intervals(x,mn,ci,color,patch_it,linestyle, DOTS)
%function hout = plot_confidence_intervals(x,mn,ci,color,patch_it)
%  x = xdimension
%  mn = the mean - assumes that this is a row vector.
%  ci = 2 rows  - 1st row is upper confidence interval, 2nd is the lower.
%  ALSO: if ci is a function handle - this will be the way confidence
%  intervals are generated: @normci, @notch_ci
%
%  color = the color
%  patch_it = make a pretty alpha  WARNING: ppt does not like apha and patches when
%  ungrouped.
%  DOTS = use dots instead of connected lines.
%
% cowen 2006,2019
if nargin < 3
    ci = [];
end

if nargin < 4
    color = [0 0 0];
end

if nargin < 5
    patch_it = 0; % The default is 0 - because saveas freaks out sometimes
    % with patches. It appears to be completely random. Probably a video card thing.
    % It really looks pretty when it works.
end

if nargin < 6
    linestyle = '-';
end

if nargin < 7
    DOTS = false;
end

if isempty(x)
    x = 1:length(mn);
end

if nargin == 1 || isempty(mn)
    [mn,ci] = normci(x);
    x = 1:length(mn);
end
if min(size(mn)) == 1
    mn = mn(:)'; % Convert to a row vector if it's not a matrix.
end

if size(ci,1) > 2 && size(ci,2) == 2
    ci = ci'; % Force to be 2 row vectors in case it's 2 column vectors.
end
mn(isinf(mn)) = nan;
if size(mn,1) ~= 1
    % If the user passes in a matrix, assume they want normal confidence
    % intervals.
    if isa(ci,'function_handle')
        fun = ci;
    else
        fun = @normci;
        %            fun = @notch_ci;
    end
    [mn,ci] = fun(mn);
end
x = x(:)';
% DOTS = true;

if DOTS
%     h(1) = plot(x(:),mn(:),'.','MarkerSize',18,'Color',color);
else
     h(1) = plot(x(:),mn(:),'LineWidth',2,'Color',color*.7,'LineStyle',linestyle,'Marker','none');
%     set(h(1),'LineStyle',linestyle)
end
hold on
% plot(x(:),mn(:),'.');
if ~isempty(ci)
    if DOTS
        h(1) = errorbar(x(:), mn(:)', abs(diff(ci)),'LineWidth',1.5,'Color',color,'Marker','o','MarkerFaceColor', color*.8,'LineStyle','none');
    else
        h(2) = plot(x,ci(1,:),'LineWidth',0.5,'Color',color,'LineStyle',linestyle,'Marker','none');
        h(3) = plot(x,ci(2,:),'LineWidth',0.5,'Color',color,'LineStyle',linestyle,'Marker','none');
    end
end

% Sometimes plot screws up the x axis and even though you axis tight, it
% still does not tighten the x axis. The following code fixes this.
axis tight % Fix the y axis

a = axis;
a(1:2) = x([1 end]);
axis(a)

if patch_it
    % Pretty alpha blended intervals - but dangerous as it crashes
    %  I have tried to fix it but get frustrated - Best to just suck it up.
    % Also: IMporting patched plots with alpha into ppt leads to disaster as once you ungroup the
    % figure - it screws up the colors and kills the alpha.
    X = [x;x;[x(2:end);x(2:end)] [x(end) ; x(end)]];
    Y = [ci;ci(:,2:end) ci(:,end)];
    X(:,end) = [];
    Y(:,end) = [];
    
    Y = Y([1 2 4 3],:);
    % h2 = fill(X, Y,color);
    h2 = patch(X, Y,color);
    %set(h2,'EdgeColor',color);
    set(h2,'FaceAlpha',.2);
    set(h2,'EdgeAlpha',.2);
    set(h2,'LineStyle','none')
end
if nargout > 0
    hout = h;
end
% pubify_figure_axis