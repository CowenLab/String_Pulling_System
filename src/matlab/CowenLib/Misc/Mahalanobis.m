function d = mahalanobis(Y,X,perc_variance_thresh,pc_transform);
% MAHAL Mahalanobis distance.
%   MAHAL(Y,X) gives the Mahalanobis distance of each point in
%   Y from the sample in X. 
%   
%   The number of columns of Y must equal the number
%   of columns in X, but the number of rows may differ.
%   The number of rows must exceed the number of columns
%   in X.

%   B.A. Jones 2-04-95
%   Copyright (c) 1993-98 by The MathWorks, Inc.
%   $Revision: 2.5 $  $Date: 1997/11/29 01:45:49 $

% do svd to get rid of the singleton dimenstions.
if nargin < 3
    perc_variance_thresh = 98;
    pc_transform = 1;
end
if nargin < 4
    pc_transform = 1;
end

if pc_transform
    [U,latent,pc] = svd(X,0);
    wt_explained = latent/sum(latent);
    pcs_to_use = min(find(cumsum(wt_explained)>(perc_variance_thresh/100)));
    
    X = X*pc(:,1:pcs_to_use);
    Y = Y*pc(:,1:pcs_to_use);
end


[rx,cx] = size(X);
[ry,cy] = size(Y);
n_to_add = 0;
if cx ~= cy
   error('Requires the inputs to have the same number of columns.');
end
old_rx = rx;
if rx < cx
  n_to_add = cx-rx+1;
  rx = rx + n_to_add;
  % Add some random rows so that the rows in X exceed the number of columns
  X = [X; X(round(rand(n_to_add,1)*(old_rx-1)+1),:)];
  %disp('The number of rows of X must exceed the number of columns.');
end

m = mean(X);
C = X - m(ones(rx,1),:);
[Q,R] = qr(C,0);
R = R./sqrt(rx-1);
ri = R\eye(cx,cx);

M = m(ones(ry,1),:);
E = ((Y-M)*ri)';
d = sum(E.*E)';
