function varargout = Condense_R(varargin)
% Clean up the R, only looking at the upper diagonal and  non nans.
[N, n] = size(varargin{1});
if n~=N
    error('must be a square matrix')
end

idx = find(triu(ones(N,N))==0); % Must be 0, else you get the diagonal

for ii = 1:nargout
    if size(varargin{ii},1) ~= N
        error('All matrices must have the same size')
    end
    varargout{ii} = varargin{ii}(idx); % The upper diagonal converted to a vector
end
