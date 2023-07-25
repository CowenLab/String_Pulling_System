function [hb, he] = errorbar_by_group(M,npergroup,error_function, colors)
% Plot grouped data where grouping is by chunks of columns. Pass in how
% many adjacent columns constitute a group and an error bar plot is created
% with those groups.
if nargin < 2
    npergroup = [];
    error_function = @normci;
end

if length(npergroup) > 1 | isempty(npergroup)
    g = npergroup;
    if iscell(M)
        [M,g] =group_data(M);
    end
    % user passed in category infromation.
    gs = unique(g);
    ncols = Cols(M);
    for iG = 1:length(gs)
        ix  = find(g == gs(iG));
        [m,ci] = error_function(M(ix,:));
        bar([1:ncols] + (iG-1)*ncols,m,'FaceColor',colors(iG,:))
        hold on
        colormap(gray)
        h = errorbarci([1:ncols] + (iG-1)*ncols,m,ci,'r.')
       set(h,'MarkerSize',0)
        %set(h,'LineWidth',3)
        
    end
%    set(gca,'XTick',1:length(gs))
%    a  = axis;
%    a(2) = ncols + length(gs)-a(1);
%    axis(a);
else
    ngroups = Cols(M)/npergroup;
    [m,ci] = error_function(M);
    r = reshape(1:Cols(M),npergroup,ngroups);
    r = r + repmat(0:(ngroups-1),npergroup,1);
    x = sort(r(:))';
    
    hb = barc(x, m, repmat(colors,ngroups,1));
   %set(hb,'LineWidth',1)
    hold on
    he = errorbarci(x, m, ci);
    %set(he,'LineWidth',1)
    set(gca,'XTick',nanmedian(r))
    a  = axis;
    a(2) = max(x) + 1;
    axis(a);
end
