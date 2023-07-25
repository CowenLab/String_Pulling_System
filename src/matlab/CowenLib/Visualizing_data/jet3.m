function j = jet3(n)

if nargin == 1
    j = jet(n);
else
    j = jet;
end
j(1,:) = [1 1 1];
