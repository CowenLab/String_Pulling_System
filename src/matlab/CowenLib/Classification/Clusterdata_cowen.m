function [C] = Clusterdata_cowen(D, val1,val2, plot_it)

if nargin < 2
    val1 = 'maxclust';
end
if nargin < 3
    val2  = 5;
end
if nargin < 4
    plot_it = true;
end
if isempty(val2)
    cix = clusterdata(D,val1);
else
    cix = clusterdata(D,val1,val2);
end

% cix = clusterdata(D,th);
u = unique(cix);

if plot_it
    [pc,sc] = pca(D);
    figure
    plot(pc(:,1:4));
    legend({'1' '2' '3' '4'})
    figure
    scatter3(sc(:,1),sc(:,2),sc(:,3),100,cix,'filled')
    %     for ii = 1:length(u)
    %         IX = cix ==u(ii);
    %     subplot(2,2,1)
    %     plot(sc(IX,1),sc(IX,2),'.', 'Color', j(ii,:))
    %     subplot(2,2,2)
    %     plot(sc(IX,2),sc(IX,3),'.', 'Color', j(ii,:))
    %     subplot(2,2,3)
    %     plot(sc(IX,3),sc(IX,4),'.', 'Color', j(ii,:))
    %     subplot(2,2,4)
    %     plot(sc(IX,4),sc(IX,5),'.', 'Color', j(ii,:))
    %     end
end