function O = errorbar_cowen(MN,labels,LineSpec,LineWidth,MarkerSize)
% pass in a matrix of the data where each col is a variable 
% Nice errorbar plot of SEM
% 
% Cowen 2010
if nargin < 2 || isempty(labels)
    labels = 1:Cols(MN);
end

if nargin < 3 || isempty(LineSpec)
    LineSpec = 'k.-';
end

if nargin < 4 || isempty(LineWidth)
    LineWidth = 2;
end

if nargin < 5 || isempty(MarkerSize)
    MarkerSize = 0.01; % usually you don't want markers for errorbar plots.
end

E = Sem(MN);
%E = nanstd(MN);

h = errorbar(1:Cols(MN),nanmean(MN),E,LineSpec,'LineWidth',LineWidth,'MarkerSize',MarkerSize);
set(gca,'XTick',1:length(labels))
set(gca,'XTickLabel',labels)
pubify_figure_axis

if nargout > 0
    O = h;
end