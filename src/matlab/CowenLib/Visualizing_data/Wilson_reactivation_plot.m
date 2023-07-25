function Wilson_reactivation_plot(Cell1_and_Cell2, r_value, threshold)
% Input
%   the cell ids for the cell pairs that made up the r_value
%    assumes ids range from 1 to ncells
%   a cell array of r_values where each element in the array is an epoch.
% OUTPUT:
%   A figure remeniscent of the Wilson and Mcnaughton figures from the science paper.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nplots = length(r_value);
if nargin == 3
    % apply a threshold to the data and don't plot this data.
    for ep = 1:nplots
        r_value{ep}(find(r_value{ep}<threshold)) = nan;
    end
end


mn = min(Cell1_and_Cell2(:));mx = max(Cell1_and_Cell2(:));
[x,y]=circle(mx,1);
c = colormap(jet);
mx_r = 0;
mn_r = inf;
for ep = 1:nplots
    mx_r = max([mx_r; r_value{ep}(find(r_value{ep}<inf))]);
    mn_r = min([mn_r; r_value{ep}]);
end

for ep = 1:nplots
    subplot(1,nplots,ep)
    hold on
    for ii = 1:length(r_value{ep})
        if ~isinf(r_value{ep}(ii)) & ~isnan(r_value{ep}(ii))
            h = line([x(Cell1_and_Cell2(ii,1)) x(Cell1_and_Cell2(ii,2))],[y(Cell1_and_Cell2(ii,1)) y(Cell1_and_Cell2(ii,2))]);
            hold on
            if mn_r < 0 
                set(h, 'Color', c(1+floor(63*((r_value{ep}(ii)-mn_r)/(mx_r-mn_r))),:));
                set(h, 'LineWidth',1+ 5*((r_value{ep}(ii)-mn_r)/(mx_r-mn_r)));
            else
                set(h, 'Color', c(1+floor(63*((r_value{ep}(ii)-mn_r)/(mx_r-mn_r))),:));
                set(h, 'LineWidth',1+ 5*((r_value{ep}(ii)-mn_r)/mx_r));
            end
        end
    end
    plot(x,y,'.k')
    warning off
    %text(x-.1,y,cellstr(1:mx),'FontSize',6)
    warning on
    
    axis square
    axis off
end
