%This m-file is called Bcomprate.m
%y=Bcomprate(k,x) yields the lowest compression
%rate achievable using block codes of order k
%to encode the data vector x
%The length of x must be a multiple of k
%
function y = Bcomprate(k,x)
x=x+1;
m=max(x);
n=length(x);
p=0:k-1;
v=(m+1).^p;
for i=1:n/k;
u=x(k*(i-1)+1:k*i);
x1(i)=v*u';
end
y=huffmanlength(x1)/n;

