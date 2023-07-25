function [T] = Create_template(orig_xy,n_pts,XY)
% creates a template for a 2D patter in which adjacent points ARE EQUALLY
% SPACED IN EUCLIDEAN DISTANCE!
%%
if nargin < 2
    %extra_points = 41; % The extra points are to get rid of some of the outer loop?
    n_pts = 2036;
end
if nargin < 3
    %extra_points = 41; % The extra points are to get rid of some of the outer loop?
    XY = [];
end

figure (100110)
clf
plot(orig_xy(:,1),orig_xy(:,2),'.')
xlabel('Mark the path of the rat to the center')
if isempty(XY)
    XY = get_points_until_done();
end

hold on
plot(XY(:,1),XY(:,2),'r-.')

ED_XY = sqrt(sum((XY(2:end,:) - XY(1:(end-1),:)).^2,2)); % Distance between adjacent points.
cum_ED = [0;cumsum(ED_XY)]; %CUMSUM ROCKS!!! Now I have an x axis. This ensures that the spacing between points is EQUAL! (once interpolated)

lin = linspace(0,max(cum_ED),n_pts);
T.xy(:,1) = interp1(cum_ED,XY(:,1),lin);
T.xy(:,2) = interp1(cum_ED,XY(:,2),lin);


ED_XY = zeros(Rows(T.xy)-1,1);
for ii = 1:(Rows(T.xy)-1)
    ED_XY(ii) = Euclid_dist(T.xy(ii,:),T.xy(ii+1,:));
end
new_cum_ED = [0;cumsum(ED_XY)];

% Determine the start and end points.
title('Enter the START of the active region of the template:')
T.start_xy = ginput(1);
plot(T.start_xy(1),T.start_xy(2),'r*')
title('Enter the END of the active region of the template:')
T.end_xy = ginput(1);
plot(T.end_xy(1),T.end_xy(2),'c*')
title('Enter the CENTER of the template:')
T.center_xy = ginput(1);
plot(T.center_xy(1),T.center_xy(2),'m*')


dis = Euclid_dist(T.start_xy,T.xy);
[minnn T.start_ix] = min(dis);

dis = Euclid_dist(T.end_xy,T.xy);
[minnn T.end_ix] = min(dis);
T.start_xy = T.xy(T.start_ix,:);
T.end_xy = T.xy(T.end_ix,:);

% Redo the cumuluative distance so that zero reflects the official start on
% the template.

T.cumulative_distance = new_cum_ED - new_cum_ED(T.start_ix);
T.end_cum_dist = T.cumulative_distance(T.end_ix); % The official end of the template.
figure
subplot(3,1,1:2)
plot(T.xy(:,1),T.xy(:,2),'g',T.xy(:,1),T.xy(:,2),'r.')
subplot(3,1,3)
plot(T.cumulative_distance)

