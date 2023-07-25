function plot_raster(A,row_id,varargin)
% function plot_raster(A,row_id,varargin)
% plot vertical raster lines - like spike trains - for ensemble data.
%
% INPUT:
% A = vector of timestamps
% row_id = where on the vertical axis should this raster go? e.g., row 3.
% A can also be a cell array of timestamps.
%
% ALSO:
% You can adjust the following parameters using name-value pairs.
% 'Color',Color,'LineWidth',LineWidth,'vert_size',vert_size;
% See plot_tics - somewhat redundant.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 2 || isempty(row_id)
    if ~iscell(A)
        row_id = 1;
    end
end
if iscell(A)
    if nargin < 2 || isempty(row_id) 
        row_id = 1:length(A);
    end
    if length(row_id)==1
        error('need a unique ID for each row - send as vector or empty')
    end
    for ii = 1:length(A)
        if length(varargin)>1
            plot_raster(A{ii},row_id(ii),varargin{:});
        else
            plot_raster(A{ii},row_id(ii));
        end
        hold on
    end
    axis tight;
    return
end
% Defaults
LineWidth = 1;
Color = [0 0 0];
vert_size = 0.5;
time_divisor = 1;
make_colorful = true;

Extract_varargin;
if make_colorful
    clrs = lines(row_id);
    Color = clrs(end,:);
end

A = A(:)'/time_divisor;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The whole function boils down to this one line.
% NOTE: line() is about 70% faster than plot() and patch() is 10000% faster than
% both.
% OLD VERSION (SLOOOOOW): line([A; A], [ones(1,length(A))*row_id-vert_size; ones(1,length(A))*row_id+vert_size],'Color',Color,'LineWidth',LineWidth);
h = patch([A; A], [ones(1,length(A))*row_id-vert_size; ones(1,length(A))*row_id+vert_size],'black');
h.FaceColor = Color;
h.EdgeColor = Color;