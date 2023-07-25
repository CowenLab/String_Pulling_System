function T = Untessel_layer(I, step, n_neurons)
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
T = [];
Irows = size(I,1);
T = I(1:end,1:n_neurons);
x = I(end,n_neurons+1:end);
n_rfs = length(x)/n_neurons;
T = [T;reshape(x,n_rfs,n_neurons)];
  
%for rr = 1:step:RFrows
%  T = [T,I(rr:(rr+Irows-RFrows),:)]; 
%end
% The old and VERY slow way.
%for ii = 1:step:Irows-RFrows+1
%   T = [T;Vector(I(ii:(ii+RFrows -1),:)')]; % 
%end
