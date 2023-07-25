%The name of this m-file is huffmanlength.m
%Let x be a data vector with nonnegative integer entries
%Then y = huffmanlength(x) is the length of the encoder
%output B(x) when x is encoded via a Huffman code for x
%
function y = huffmanlength(x);
F=frequency(x);
N=length(F);
q=sort(F);
S=0;
while N>2
S=S+q(1)+q(2);
q=[q(1)+q(2) q(3:N)];
q=sort(q);
N=N-1;
end
y=S+sum(F);






