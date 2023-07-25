% Extract_varargin

%   NOT A FUNCTION -- this allows it to access the current workspace
%
%   expects varargin to consist of sequences of 'variable', value
%   sets variable to value for each pair.
%   changes the current workspace!

% ADR 1998
% Cowen 2020 - added a check to ensure the variable exists
% version L4.0
% status: PROMOTED

% The following deals wiht the rare situation when varargin is empty -
% which can happen when you call a function recursively and what to copy
% the varargins to the recursive call (Cowen)
if isempty(varargin) || length(varargin) == 1
    return
end

% Core code below
for iV = 1:2:length(varargin)
    if size(varargin{iV},2) == 1
        varargin{iV} = varargin{iV}';
    end
    if ~exist(varargin{iV},'var')
        error([varargin{iV} ' does not exist'])
    end
    eval([varargin{iV}, ' = ', 'varargin{iV+1};']);
end