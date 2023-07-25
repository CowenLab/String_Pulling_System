function [N,T,Nold] = xlsread_cowen(xls_file,data_range)
% xlsread SUCKS! Sometimes it works well, but often it gives flakey results
% where the numbers and text matrices don't match or it just decides not to
% read certain rows for no reason that I understand. This function is my attempt to kludge around
% these problems by working with the raw ouput of xlsread.
% It is slower, but at least the numeric data should
% propoer
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen (2011)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NOTE: behavior on macs and pcs can be different so this may need to be
% adjusted for.
% if ~strcmp(computer,'MACI')
% end

if nargin == 1
    [Nold,T,R] = xlsread(xls_file);
else
    [Nold,T,R] = xlsread(xls_file,1,data_range);
end
N = zeros(size(R))*nan;
% 
for ii = 1:Rows(R)
    for jj = 1:Cols(R)
        if isnumeric(R{ii,jj})
            N(ii,jj) = R{ii,jj};
        end
    end
end

