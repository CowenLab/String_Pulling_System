function yhat = loessr(x,y,xo,alpha,deg)
% LOESSR  Robust loess smoothing.
%
%   YHAT = LOESSR(X,Y,XO,ALPHA,DEG)
%
%   This function performs the robust loess smoothing for univariate data.
%   YHAT is the value of the smooth. X and Y are the observed data. XO
%   is the domain over which to evaluate the smooth YHAT. ALPHA is the 
%   smoothing parameter, and DEG is the degree of the local fit (1 or 2).
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

% get constants needed
n = length(x);
k = floor(alpha*n);
toler = 0.003;        % convergence tolerance for robust procedure
maxiter = 50;        % maximum allowed number of iterations

% set up the memory
yhat = zeros(size(xo));

% for each xo, find the k points that are closest
% First find the initial loess fit.
for i = 1:length(xo)
        dist = abs(xo(i) - x);
        [sdist,ind] = sort(dist);
        Nxo = x(ind(1:k));        % get the points in the neighborhood
        Nyo = y(ind(1:k));
        delxo = sdist(k);  %% Check this
        sdist((k+1):n) = [];
        u = sdist/delxo;
        w = (1 - u.^3).^3;
        p = wfit(Nxo,Nyo,w,deg);
        yhat(i) = polyval(p,xo(i));
        niter = 1;
        test = 1;
        ynew = yhat(i);        % get a temp variable for iterations
        while test > toler & niter <= maxiter
                % do the robust fitting procedure
        niter = niter + 1;
                yold = ynew;
                resid = Nyo - polyval(p,Nxo);        % calc residuals        
                s = median(abs(resid));
                u = min(abs(resid/(6*s)),1);        % scale so all are between 0 and 1
                r = (1-u.^2).^2;        
                nw = r.*w;
                p = wfit(Nxo,Nyo,nw,deg);        % get the fit with new weights
                ynew = polyval(p,xo(i));        % what is the value at x
                test = abs(ynew - yold);
        end
        % converged - set the value to ynew
        yhat(i) = ynew;
end

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
