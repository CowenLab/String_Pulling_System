function e = Entropy(p,norm_it)
% Calculate the entropy for a series of messages
%
% INPUT: probablilities for a series of words(a vector). 
%        The probability for each message.
% 
% OUTPUT: entropy of the system using log based 2 (bits). Entropy measures the information rate.
%         it can also be thought of as the measure of the uncertainty
%         of the contents of a message before it has been received. It 
%         is a general measure of coding efficiency. Compare it to the entropy
%         when all messages have equal probability.
% 
%
if nargin < 2
    norm_it = false;
end
% cowen 
if norm_it
    p = p/length(p);
end
e = -sum(p.*log2(eps+p));