%This file is called pseudoseq.m
%n is a positive integer
%P is a probability vector of arbitrary length k
%The vector y=pseudoseq(n,P) is a pseudorandom sequence
%of length n whose symbols come from the alphabet {0,1,...,k}
%with symbol i occuring about 100P(i)% of the time in x if
%n is large
%The vector y simulates output from a memoryless source
function y = pseudoseq(n,P)
k=length(P);
x=rand(1,n);
S(1)=0;
for i=1:k;
S(i+1)=S(i)+P(i);
S(k+1)=2;
j=find(x>=S(i) & x<S(i+1));
y(j)=(i-1)*ones(size(j));
end

