function d = bi2de(b,p)
[n,m] = size(b);
if min([m,n]) < 1
    d = [];
    return;
elseif min([n,m]) == 1
    b = b(:)';
    m = max([n,m]);
    n = 1;
end;

if nargin < 2
    p = 2;
end;
d = b * p.^[0 : m-1]';
