function plot_matrix_with_trial_conditions(x,y,M,C,CL,c_labels)
% Plots M using imagesc and also plots dots at rows specified by the matrix
% of booleans (IX). A separate color is assigned to each dot. 
% this is useful for providing information regarding trial type (e.g. error
% trial, reversal trial, high reward,...)
if nargin < 6
    c_labels = [];  
end
if nargin < 5
    CL = {'y' 'r' 'g' 'c' 'w' 'm' 'y' 'r' 'g' 'c' 'w' 'm' 'y' 'r' 'g' 'c' 'w' 'm' 'y' 'r' 'g' 'c' 'w' 'm' };
end
imagesc(x,y,M)
hold on

xpos = x((end-Cols(C)):end);

for ii = 1:Cols(C)
    yy = find(C(:,ii));
    xx = repmat(xpos(ii),length(yy),1);
    plot(xx,yy,'.','Color',CL{ii},'MarkerSize',8)
end

if ~isempty(c_labels)
    legend_color_text(c_labels, CL,6,'bottom right')
end
