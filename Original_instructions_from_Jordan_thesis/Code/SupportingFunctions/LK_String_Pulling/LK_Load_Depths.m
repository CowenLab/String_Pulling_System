function [D,T] = LK_Load_Depths(root_dir, date_to_retrieve)
% function [D,T] = LK_Load_Depths(root_dir, date_to_retrieve)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the depths for a given date.
%  Depth_Tracker.xlsx
% Assumes the excel file is one directory above.
% Estimated depths in uM
% Assumes electrodes were pushed AFTER recording so we use DepthsBefore.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2020
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 1
    root_dir = '..';
end
if nargin < 2
    load('Meta_data.mat')
    date_to_retrieve = META.recdatestr;
end
ff = find_files(fullfile(root_dir, '*Depth_Tracker.xlsx'));
assert(length(ff) == 1,'No depth file or too many depth files found.')
T = readtable(ff{1},'Range','A:F');
GIX = datenum(T.Date) < datenum(date_to_retrieve);
T = T(GIX,:);
% Assume that the last record for each tetrode is correct.
u = unique(T.Tetrode);
D = [];
for iU = 1:length(u)
    Tsub = T(T.Tetrode == u(iU),:);
    D = [D; u(iU) Tsub.DepthBefore(end)];
end