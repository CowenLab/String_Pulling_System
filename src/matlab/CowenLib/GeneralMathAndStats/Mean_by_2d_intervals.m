function M = Mean_by_2d_intervals(edges_x,edges_y,XYZ)
% performs a mean within values in an edge specified by a range of x and y.
% edges_x = 2:20:200;
% edges_y = 2:20:200;
M = zeros(length(edges_x),length(edges_y));
for ii = 1:length(edges_x)-1
    for jj = 1:length(edges_y)-1
        IX = XYZ(:,1)>=edges_x(ii) & XYZ(:,1)<edges_x(ii+1) & XYZ(:,2)>=edges_y(jj) & XYZ(:,2)<edges_y(jj+1);
        if any(IX)
            M(jj,ii) = nanmean(XYZ(IX,3));
        end
    end
end
if nargout == 0
    figure
    imagesc(M)
end