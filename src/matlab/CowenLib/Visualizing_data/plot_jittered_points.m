function plot_jittered_points(M, varargin)
% plot jittered points on the plot.
% Cowen 2021
marker_size = 18;
marker_color = [.7 .7 .7];
if iscell(M)
    x_axis = 1:length(M);
else
    x_axis = 1:Cols(M);
end
Extract_varargin

for iC = 1:length(x_axis)
    if iscell(M)
        v = M{iC};
    else
        v = M(:,iC);
    end
    x = repmat(x_axis(iC),length(v),1);
    x = x + (rand(size(x))-.5)*.2;
    hold on
    plot(x,v,'.','MarkerSize',marker_size,'Color',marker_color)
    plot(x,v,'.','MarkerSize',round(marker_size/3),'Color','k')
    
end