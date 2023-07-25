function [D,G] = group_data(varargin)
%function [D,G] = group_data(varargin)
% Groups the data by concatenating all of the data in each argin and 
% creates a group vector G that contains a unique ID for each group.
% Assumes that columns are variables and rows are samples.
D = [];
G = [];
if iscell(varargin{1})
    for ii =1:length(varargin{1})
        D = [D; varargin{1}{ii}];
        G = [G; ones(Rows(varargin{1}{ii}),1)*ii];
    end
else
    for ii =1:length(varargin)
        D = [D; varargin{ii}];
        G = [G; ones(Rows(varargin{ii}),1)*ii];
    end
end