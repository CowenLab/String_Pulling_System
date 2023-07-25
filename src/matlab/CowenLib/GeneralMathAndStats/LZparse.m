%This m-file is called LZparse.m
%It accomplishes Lempel-Ziv parsing of a binary
%data vector
%x is a binary data vector
%y = LZparse(x) is a vector consisting of the indices
%of the blocks in the Lempel-Ziv parsing of x
% 
function y = LZparse(x)
N=length(x);
dict=[];
lengthdict=0;
while lengthdict < N
i=lengthdict+1;
k=0;
while k==0
v=x(lengthdict+1:i);
j=bitstring_to_index(v);
A=(dict~=j);
k=prod(A);
if i==N
k=1;
else
end
i=i+1;
end
dict=[dict j];
lengthdict=lengthdict + length(v);
end 
y=dict;






