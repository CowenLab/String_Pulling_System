function j = jet2(n)

if nargin == 1
    j = jet(n);
else
    j = jet;
end
j(1,:) = [0 0 0];
