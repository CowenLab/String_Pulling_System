function [counts nzeros IX] = Count_in_quadrants(xy)
% function [counts nzeros] = Count_in_quadrants(xy)
%
% Counts the number of points in each of the four quadrants defined by the
% intersection of the zero lines. xy = a 2 col matrix where col1 = x and
% col 2 = y.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
counts = zeros(2,2);

IX{1,2} = xy(:,1) < 0 & xy(:,2) >0; % upper left
IX{2,2} = xy(:,1) > 0 & xy(:,2) >0; % upper right
IX{1,1} = xy(:,1) < 0 & xy(:,2) <0; % lower left
IX{2,1} = xy(:,1) > 0 & xy(:,2) <0; % lower right

% Translate this into quadrants!!!!
counts(2) = nansum(IX{1,1});
counts(1) = nansum(IX{1,2});
counts(4) = nansum(IX{2,1});
counts(3) = nansum(IX{2,2});

nzeros = sum(xy(:,1) ==0 | xy(:,2) ==0);

% 
% IX{1,1} = xy(:,1) < 0 & xy(:,2) >0; % upper left
% IX{1,2} = xy(:,1) > 0 & xy(:,2) >0; % upper right
% IX{2,1} = xy(:,1) < 0 & xy(:,2) <0; % lower left
% IX{2,2} = xy(:,1) > 0 & xy(:,2) <0; % lower right
% 
% counts(1,1) = nansum(IX{1,1});
% counts(1,2) = nansum(IX{1,2});
% counts(2,1) = nansum(IX{2,1});
% counts(2,2) = nansum(IX{2,2});

