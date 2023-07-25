%This m-file is named block_entropy.m
%block_entropy(k,x) computes k-th order entropy
%of the data vector x
%The length of x must be a multiple of k
%
function y = block_entropy(k,x)
x=x+1;
m=max(x);
n=length(x);
p=0:k-1;
v=(m+1).^p;
for i=1:n/k;
u=x(k*(i-1)+1:k*i);
x1(i)=v*u';
end
y=entropy(x1)/k;

