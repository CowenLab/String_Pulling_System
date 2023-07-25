function O = is_angle_between(n, a, b, use_radians)
% Determines if n is between a and b.
%a = 220; b = 140; n = 9;
if nargin < 4
    use_radians = false;
end
if use_radians
    mf = 2*pi;
else
    mf = 360;
end

n1 = mod(mf + mod(n,mf),mf);
a1 = mod((mf*10000 + a) , mf);
b1 = mod((mf*10000 + b) , mf);
if (a < b)
    O = a1 <= n1 && n1 <= b1;
else
    O = a1 <= n1 || n1 <= b1;
end