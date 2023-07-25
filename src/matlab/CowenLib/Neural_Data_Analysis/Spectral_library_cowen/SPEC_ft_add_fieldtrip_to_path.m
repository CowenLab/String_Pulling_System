function SPEC_ft_add_fieldtrip_to_path(fd)
% You only have to do this once.
if nargin < 1
    fd = 'G:\Temp\fieldtrip-20210128';
end
addpath(fd);
ft_defaults