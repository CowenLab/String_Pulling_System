function within = lyngby_km_within(X, Centers, assign, varargin)

% lyngby_km_within     - K-means within-variance (within intertia)
%
%    function W = lyngby_km_within(X, Centers, assign, ...
%           'PropertyName', 'PropertyValue')
%
%       Input:    X         Datamatrix, size: examples x
%                           variables. ie. if voxels are to be clustered
%                           the datamatrix should be voxels x time.
%                 Centers   Cluster center matrix
%                 assign    Assignment vector
%    
%       Property: Type      [ {trace} | det | matrix ]
%
%     Output:      within    The within variance    
%
%       This function calculates the within cluster variance, ie., the
%       within within inertia.
%
%       See also LYNGBY, LYNGBY_KM_MAIN, LYNGBY_KM_CENTERSIM.
%
% $Id: lyngby_km_within.m,v 1.2 2003/01/31 20:04:30 fnielsen Exp $ 



    % Sizes
    [rX, cX]  = size(X);
    [rCenters, cCenters] = size(Centers);
    [rAssign, cAssign] = size(assign);
    nClusters = rCenters;   % Number of clusters
    nDim = cX;
    
    % Check arguments and sizes
    if nargin < 3
      error('Too few arguments');
    end
    
    
    % Default properties
    Type       = 'trace'; 

    
    % Parse properties
    n = 1;
    while n < length(varargin)+1
      arg = lower(varargin{n});
      
      if strcmp(arg, 'type')
    n = n + 1;
    arg = lower(varargin{n});
    if strcmp(arg, 'trace')
      Type = 'trace';
    elseif strcmp(arg, 'det')
      Type = 'det';
    elseif strcmp(arg, 'matrix')
      Type = 'matrix';

    else
      error(sprintf('Type ''%s'' not recognized', arg));
    end
    
      else
    error(sprintf('Invalid property: %s', arg));
      end
      n = n + 1;
    end

    
    if strcmp(Type, 'trace');
      within = 0;
      for c = 1:nClusters
    index = find(assign==c);
    within = within + ...
        sum(sum( (X(index,:) - ...
        repmat(Centers(c,:), length(index), 1)).^2 )); 
      end
    elseif strcmp(Type, 'det')
      within = zeros(nDim, nDim);
      for c = 1:nClusters
    index = find(assign==c);
    within = within + ...
        ((X(index,:) - repmat(Centers(c,:), length(index), 1))' * ...
        (X(index,:) - repmat(Centers(c,:), length(index), 1)));  
      end
      within = det(within);
      
    elseif strcmp(Type, 'matrix')
      within = zeros(nDim, nDim);
      for c = 1:nClusters
    index = find(assign==c);
    within = within + ...
        ((X(index,:) - repmat(Centers(c,:), length(index), 1))' * ...
        (X(index,:) - repmat(Centers(c,:), length(index), 1)));  
      end
    else
      error(sprintf('Internal error: Type = %s', Type));
    end















