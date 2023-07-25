%This m-file is called frequency.m
%x is a data vector with nonnegative integer components
%F=frequency(x) is the vector whose components are the
%frequencies with which each symbol in x appears in x,
%from most frequent to least frequent
%
function F = frequency(x)
k=max(x)+1;
for i=1:k;
j=find(x==i-1);
u(i)=length(j);
end
r=find(u>0);
v=u(r);
v=sort(v);
m=length(v);
for i=1:m;
F(i)=v(m-i+1);
end


