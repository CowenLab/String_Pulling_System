function [s,isiA] = Spike_precision(A,B)
% Estimate the precision between two spike trains. Precision is defined as a 
% low variation in the interval between spikes in A relative to the nearest spike
% in B. Practically, the distribution of the ISIs between the spikes of A and the
% nearest spike in B is calculated. The std of this diestribution is returned as s.
% The raw values are returned as isiA.
% INPUT: vector or ts object of timestamps for A and B
% OUTPUT: s = std of isis of spikes in A with it's closest neighbor in B.
%         isiA = the isi's

% cowen
if isa(A,'ts')
    A = Data(A);
end
if isa(B,'ts')
    B = Data(B);
end
isiA = zeros(1,length(A));
for ii = 1:length(A)
    b = binsearch(B,A(ii));
    isiA(ii) = B(b)-A(ii);
end
s = std(isiA);

