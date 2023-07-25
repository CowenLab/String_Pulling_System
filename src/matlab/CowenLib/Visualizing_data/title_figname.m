function title_figname(varargin)
% Copies the title of the plot to the title of the figure;
title(varargin)
set(gcf,'Name',varargin{1})
