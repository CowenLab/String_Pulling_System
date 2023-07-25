function [d,gxor,gor,gand] = xor_test_set()
% return the classic xor test set with some noise.
d1 = repmat([0 1],100,1);
d2 = repmat([1 0],100,1);
d3 = repmat([1 1],100,1);
d4 = repmat([0 0],100,1);
d = [d1;d2;d3;d4];
d = d + randn(size(d))*.2;
gxor = [ones(200,1);ones(200,1)+1];
gor  = [ones(300,1);ones(100,1)+1];
gand = [ones(200,1);ones(100,1)+1;ones(100,1)];