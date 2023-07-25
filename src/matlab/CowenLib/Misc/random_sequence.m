function [r, idx] = random_sequence(A,allow_repeats)
% Create a vector r that has the same distribution of elements as
% in A, but randomly chosen. 
% idx are the indices in A that were chosen -- in the proper order of
% choosing.
%
if nargin < 2
    allow_repeats = 1;
end
r = zeros(size(A))*nan;
len = length(A);
idx = ceil(rand(1,1)*len);
r(1) = A(idx); % Choose a random starting point
for ii = 2:len
    % choose a random sample from tmpseq{3} and make sure it 
    % isn't the same as the current sample
    chosen = 0;
    if allow_repeats == 0
        while chosen == 0
            idx(ii) = ceil(rand*len);
            chosen = A(idx(ii));
            if chosen == r(ii-1)
                chosen = 0;
            end                       
        end
    else
        chosen = A(ceil(rand*len));
    end
    r(ii) = chosen;
end
