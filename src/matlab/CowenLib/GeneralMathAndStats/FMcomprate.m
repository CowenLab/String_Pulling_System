%This m-file is called FMcomprate.m
%FMcomprate(k,x) computes the minimum compression
%rate achievable in the encoding of the data vector x
%using k-th order finite memory codes
%
function y = FMcomprate(k,x)
u=x(1:k);
S=huffmanlength(u);
n=length(x);
M(:,1)=u';
for i=2:n-k;
v=x(i:i+k-1)';
I=1;
z=0;
[r,s]=size(M);
while z==0
w=M(:,I);
if v==w
z=1;
elseif I==s
z=1;
M(:,s+1)=v;
else
I=I+1;
end
end
end
[r,s]=size(M);
for i=1:s;
v=M(:,i);
t=[];
for j=1:n-k;
w=x(j:j+k-1)';
if w==v
t=[t x(j+k)];
else
end
end
S=S+huffmanlength(t);
end
y=S/n;

