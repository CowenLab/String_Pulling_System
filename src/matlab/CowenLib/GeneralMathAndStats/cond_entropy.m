%This m-file is called cond_entropy.m
%cond_entropy(k,x) is the k-th order conditional
%entropy of the data vector x
%
function y = cond_entropy(k,x)
u=x(1:k);
S=k*entropy(u);
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
S=S+length(t)*entropy(t);
end
y=S/n;

