%The name of this m-file is entropy.m
%x is a data vector
%y=entropy(x) is the entropy of x
%
function y = entropy(x)
P=frequency(x)/length(x);
y=sum(-P.*log2(P));

