function [yhat, yhatlo, xlo, yhatup, xup] = loessenv(x,y,xo,alpha,deg,flag)
% LOESSENV    Loess smooth with upper and lower envelopes.
%
%   [YHAT,YLO,XLO,YUP,XUP] = LOESSENV(X,Y,XO,ALPHA,DEG,FLAG)
%
%   This finds the loess smooth based on the observed data in X and Y
%   at the domain values given in XO. ALPHA is the smoothing parameter
%   and DEG is the degree of the local polynomial fit. 
%   FLAG indicates whether or not the robust loess is used. 
%   FLAG = 1 indicates a robust loess. FLAG = 0 indicates regular loess.
%

%   W. L. and A. R. Martinez, 3-4-04


if deg ~= 1 & deg ~= 2
        error('Degree of local fit must be 1 or 2')
end
if alpha <= 0 | alpha >= 1
        error('Alpha must be between 0 and 1')
end
if length(x) ~= length(y)
        error('Input vectors do not have the same length.')
end


% make sure these are sorted properly for plotting purposes
[xs,ind]=sort(x);
ys = y(ind);
x = xs;
y = ys;

% now do the envelopes
% find the yhat at the observed data values using loess
if flag == 1
        yh = loessr(x,y,x,alpha,deg);
else
        yh = loess(x,y,x,alpha,deg);
end
yhat = yh;
% find the residuals
resid = y - yh;
% find the positive residuals and corresponding pairs
indp = find(resid>=0);
xp = x(indp);
yp = yh(indp);
rp = resid(indp);
% find the negative residuals and corresponding pairs
indn = find(resid < 0 );
xn = x(indn);
yn = yh(indn);
rn = resid(indn);
% smooth the (x,r) pairs
if flag == 1        % then do the robust version
        yup = loessr(xp,rp,xp,alpha,deg);
        ylo = loessr(xn,rn,xn,alpha,deg);
else
        yup = loess(xp,rp,xp,alpha,deg);
        ylo = loess(xn,rn,xn,alpha,deg);
end
% Add the smooths to the yhat's to get the upper and lower envelopes
yhatup = yp + yup;
yhatlo = yn + ylo;
xlo = xn;
xup = xp;

function p = wfit(x,y,w,deg)
% This will perform the weighted least squares
n = length(x);
x = x(:);
y = y(:);
w = w(:);
% get matrices
W = spdiags(w,0,n,n);
A = vander(x);
A(:,1:length(x)-deg-1) = [];
V = A'*W*A;
Y = A'*W*y;
[Q,R] = qr(V,0); 
p = R\(Q'*Y); 
p = p';                % to fit MATLAB convention
