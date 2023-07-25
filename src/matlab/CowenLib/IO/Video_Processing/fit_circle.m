function [xc, yc, last_jump] = fit_circle(x, y, xc_guess, yc_guess, r, max_iter);
% FIT_CIRCLE use Gauss-Newton method to fit a circle of known radius to a set of data points
%     [xc yc] = fit_circle(x, y, xc_guess, yc_guess, r);
%  Input:
%     x = column vector of x-coordinates from data
%     y = column vector of y-coordinates from data
%     xc_guess = best guess as to x coord center of circle
%     yc_guess = best guess as to y coord of center of circle
%     r = radius of circle to fit
%  Ouput:
%     xc = x-coord of circle center
%     yc = y-coord of circle center
%     last_jump = last jump made by algorithm as it approached a solution.  
%                 If this number is large (>1e-3), the algorithm failed to converge and you may need
%                 more iterations

% David Euston   3/17/2003

if nargin<6
   max_iter = 10;
end;

p=[xc_guess yc_guess]'; 
iter=0; 
dp=1;

while norm(dp)> 1e-6 & iter<max_iter
    
    iter=iter+1; 
    xc = p(1);
    yc = p(2);
    
    %hold on;
    %plot(xc, yc, 'xb');
    
    xd=x-xc; 
    yd=y-yc;
    f=xd.^2/r^2+yd.^2/r^2-1;
    J=-2*[xd/r^2 yd/r^2];
    dp=-J\f;
    p=p+dp; %Gauss-Newton
end
xc=p(1);
yc=p(2);
last_jump = norm(dp);

return;