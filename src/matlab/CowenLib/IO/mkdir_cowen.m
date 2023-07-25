function mkdir_cowen(varargin)
% makes a series of directories and does the exist check.
% Cowen 2023
try
for ii = 1:length(varargin{1})
    [status, msg, msgID] = mkdir(varargin{1}{ii});
end
end