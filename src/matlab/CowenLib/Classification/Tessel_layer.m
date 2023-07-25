function T = Tessel_layer(I, step, RFrows, method)
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
error('Use tessel_matrix from now on')