%This m-file is named LZcodelength.m
%x = a binary data vector
%LZcodelength(x) = length in codebits of the encoder
%output resulting from the Lempel-Ziv coding of x
%
function y = LZcodelength(x)
u=LZparse(x);
t=length(u);
S=0;
for i=1:t;
S=S+ceil(log2(2*i));
end
y=S;

