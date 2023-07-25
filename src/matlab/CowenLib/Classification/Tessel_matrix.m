function T = Tessel_matrix(I, step, RFrows, method)
% Tesselate a matrix. This is used to create a new input layer that embodies
% the receptive fields of the layer.
%INPUT:
% I = input matrix
% step
% RF_rows = size of the receptive field in rows(1D receptive fields only)
%
%OUTPUT:
% T = Tesselated receptive field
%
% cowen
% This function is very slow. Getting rid of the for loop would help a lot.
%
% 9/4 transposed the I matrix fixing a bug.
% 10/5 Made it run 10 times faster by vectorizing.

if nargin == 3
  method = 'csr'
end

[rows,cols] = size(I);

switch method
case 'csr'
  
  T = [];
  %T = zeros(RFrows/step,
  for rr = 1:step:RFrows
    T = [T,I(rr:(rr+rows-RFrows),:)]; 
  end
case 'by_col'
  T = zeros(rows-RFrows+1,RFrows*cols);
  idx  = [];
  for ii = 1:RFrows
    idx = [idx;[ii:(rows-RFrows+ii)]];
  end
  
  %D = [];
  for ii = 1:cols
    % Use one cell.
    vI = I(:,ii);
    %D = [D,v(idx)'];
    T(:,(ii*RFrows-RFrows+1):ii*RFrows) = vI(idx)';
  end
otherwise
  error('incorrect method')
end


% The old and VERY slow way.
%for ii = 1:step:Irows-RFrows+1
%   T = [T;Vector(I(ii:(ii+RFrows -1),:)')]; % 
%end
