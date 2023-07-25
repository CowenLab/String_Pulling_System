function [Z, V, W] = Vector_Stats_Bootstrap_Algor(phi)

% Vector_Stats_Bootstrap_Algor.m

% Calculate values needed for finding confidence interval about vector mean,
%  using resampling methods.  Input data can be resampled or original.
%  Calculates first matrix U that is covariance of cos(phi), sin(phi),
%  then others as returned

% Input variable:
%   phi: Data azimuth values in this (re)sample (radians)
% Output variables:
%   Z: mean vector
%   V: square root of positive definite symmetric matrix U
%   W: inverse of square root (V) of pos. def. symmetric matrix U

% Ref.: Fisher, 1993, p. 199-207, 210-211

Nd = length(phi);
xx = cos(phi);
yy = sin(phi);

% algorithm 1: mean vector Z and covariance matrix U of cos,sin

z1 = sum(xx)/Nd;
z2 = sum(yy)/Nd;
Z = [z1; z2];

u11 = sum((xx - z1).^2)/Nd;
u22 = sum((yy - z2).^2)/Nd;
u12 = sum((xx - z1).*(yy - z2))/Nd;
U = [u11, u12; u12, u22];

% algorithm 2: square root of positive definite symmetric matrix U

a = (u11 - u22)/(2*u12);  
beta = a - sqrt(a*a + 1);
b = 1 + beta*beta;
t1 = sqrt((beta*beta*u11 + 2*beta*u12 + u22)/b);
t2 = sqrt((u11 - 2*beta*u12 + beta*beta*u22)/b);
v11 = (beta*beta*t1 + t2)/b;
v22 = (t1 + beta*beta*t2)/b;
v12 = beta*(t1 - t2)/b;
V = [v11, v12; v12, v22];

% algorithm 3: inverse of square root (V) of P. D. symmetric matrix U

t1 = 1/t1;
t2 = 1/t2;
w11 = (beta*beta*t1 + t2)/b;
w22 = (t1 + beta*beta*t2)/b;
w12 = beta*(t1 - t2)/b;
W = [w11, w12; w12, w22];
