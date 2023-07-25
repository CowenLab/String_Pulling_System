function MS = Smooth_matrix(M,x_factor,y_factor)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Smooths a jagged matrix M by spline interpolation between points
% Cowen 2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 2
    y_factor = x_factor;
end
[I,J] = ind2sub(size(M),1:length(M(:)));
[y,x] = meshgrid(linspace(min(I),max(I),x_factor),linspace(min(J),max(J),y_factor));
[Z] = interp2( M,x(:)',y(:)');%,'spline');
MS= reshape(Z, x_factor,y_factor)';