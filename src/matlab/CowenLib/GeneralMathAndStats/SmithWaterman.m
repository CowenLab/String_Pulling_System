function [opt,opt_x,opt_y,D] = SmithWaterman(x,y,d,delta)
S = Score(x,y,d);
% Edit the score matrix.
n = length(x); m = length(y);
D = [zeros(1,m+1); zeros(n,1) S];
T = zeros(n,m);
for i=2:(n+1)
    for j=2:(m+1)
        [D(i,j),T(i-1,j-1)] = max([0; D(i-1,j-1)+D(i,j); ...
                D(i-1,j)-delta; D(i,j-1)-delta]);
    end
end
D = D(2:end,2:end);
% Trace back the optimal score.
[opt ,I] = max(D(1:end));
j = ceil(I/n); opt_y = [];
i = I - n*(j-1); opt_x = [];
while (i*j > 0 & D(i,j) > 0)
    opt_y = [j opt_y];
    opt_x = [i opt_x];
    switch T(i,j)
    case 2
        i = i-1; j = j-1;
    case 3
        i = i-1;
    case 4
        j = j-1;
    end
end
% Plot the dot matrix
if nargout == 0
    contour(D)
    hold on
    plot(opt_y,opt_x, '*red')
    hold off
end