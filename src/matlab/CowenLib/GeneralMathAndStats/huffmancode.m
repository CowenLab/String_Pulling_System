%The name of this m-file is huffmancode.m
%x is a data vector with nonnegative integer components
%y=huffmancode(x) is the Kraft vector of a Huffman
%code for x
%
function y = huffmancode(x)
F=frequency(x);
k=length(F);
M=zeros(k,k+1);
M(:,1)=F';
R=k;
while R > 1
v=M(:,1);
[u,j]=sort(v);
j1=min(j(1),j(2));
j2=max(j(1),j(2));
r1=M(j1,:);
r2=M(j2,:);
t1=find(r1==0);
t2=find(r2==0);
m1=min(t1);
m2=min(t2);
if m1 > 2
m1=m1-1;
else
end
if m2 > 2
m2=m2-1;
else
end
v1=r1(2:m1);
v2=r2(2:m2);
bottom=[r1(1)+r2(1) v1+1 v2+1 zeros(1,k+2-m1-m2)];
N=zeros(R-1,k+1);
for i=1:k+1;
s1=1:j1-1;
s2=j1+1:j2-1;
s3=j2+1:R;
Q=M(:,i)';
Qnew=[Q(s1) Q(s2) Q(s3) bottom(i)];
N(:,i)=Qnew';
end
R=R-1;
M=N;
end
z=M(1,2:k+1);
y=sort(z);

