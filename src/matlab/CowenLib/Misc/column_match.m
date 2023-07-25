function [idx] = column_match(M, varargin)
% Pass in a matrix followed by a number of arguments equal to the number of
% columns in the matrix. each argument is the conditional statement for
% inclusion
%
% column_match(M,[1 2], [], 10, [1:10])
% you passed in a matrix with 4 colmns, return the rows that have a 1 or 2
% in the first col, anythin in the second, a 10 in the third and 1:10 in
% the fourth.
% 
% Cowen
[nrows,ncols] = size(M);

Z = zeros(nrows,1);

for ii = 1:length(varargin)
    if isempty(varargin{ii})
        Z = Z + 1; % increment, this assumes that you want everything in this column
    else
        % Only increment those items that match the itmes in hte varargin.
        if length(varargin) == 1
            idx = find(M(:,ii)==varargin{ii});
        else
            % This would work for the length(varargin) == 1 case as well,
            % but I think that it is slower.
            idx = find(ismember(M(:,ii),varargin{ii}));
        end
        Z(idx) = Z(idx) + 1;
    end
end
idx = find(Z == ncols)';
