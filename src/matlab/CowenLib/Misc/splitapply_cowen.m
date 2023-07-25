function [M,UG,nUG] = splitapply_cowen(fun,varargin)
% The normal splitapply does not work with 2D output. This does.
%
% Cowen 2017
% TWO_LEVELS_OF_GROUPING = false;
G = varargin{end};
% if min (size(G)) > 1
%     % TO DO: user wants to do 2 levels of grouping, first on the first column,
%     % and then averaging these values based on the second column. THIS
%     % ASSUMES G is in COLUMN format with each column being a unique
%     % grouping factor with the first column being a subset of the group in
%     % the second column (hierarchy with second column being at the top).
%     % 
%     TWO_LEVELS_OF_GROUPING = true;
%     G2 = G(:,2);
%     G = G(:,1);   
%     error('Not implemented yet')
% end

V = varargin(1:(length(varargin)-1));
UG = unique(G);
M = []; VV = [];
nUG = zeros(length(UG),1);
for iG = 1:length(UG)
    IX = G == UG(iG);
    N = false(1,sum(IX));
    for ii = 1:length(V)
        VV{ii} = V{ii}(IX);
        N = N | isnan(VV{ii});
    end
    
    nUG(iG) = sum(~N); % number of non-nan values. The true number of matches.

    M(:,:,iG) = fun(VV{:});
end
