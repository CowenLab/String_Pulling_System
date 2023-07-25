function hh = histogram_cowen(H,bin_sz,colors,style,normalization,overlay_pdf)
% Go - to histogram function. Saves a lot of space 
% Will overlay pdf if you would like.
% TODO: The bars are not centered in the middle of the edges. FIX
% Cowen - 2019
if 0
    a = randn(100,1) * 1;
    b = randn(30,1) *1.2 + .2;

    figure;
    histogram_cowen({a,b})
end

if nargin < 6 
    overlay_pdf = false;
end
if nargin < 5
    normalization = 'count';
    %      normalization = 'pdf';
end
if nargin < 4 || isempty(style)
    style = 'stairs';
end
if nargin < 3 || isempty(colors)
    colors = lines(length(H));
end
if nargin < 2
    bin_sz = [];
end

cla
hh = cell(length(H),1);
for iH = 1:length(H)
    h = histogram(H{iH},15);
    if ~isempty(bin_sz)
        if length(bin_sz) >1
            h.BinEdges = bin_sz;
        else
            h.BinWidth = bin_sz;
        end
    else
        if iH == 1
            bin_sz =  h.BinWidth;
        end
    end
    % What does this do? It shifts things over a little so that group
    % differences can be better seen.
    if length(bin_sz) == 1
        h.BinEdges = h.BinEdges + h.BinWidth*.05*(iH-1);
    end
            
    % h(iH).FaceAlpha  =.4;
    if strcmpi(style,'stairs')
        h.FaceColor = 'none';
    else
        h.FaceColor = colors(iH,:);
    end
    h.EdgeColor = colors(iH,:);
    h.Normalization = normalization;
    h.FaceAlpha = .2;
    h.DisplayStyle=style;
    h.LineWidth = 4;
    hold on
    hh{iH} = h;
    if overlay_pdf
        [d,x] = ksdensity(H{iH});
        plot(x,d,'Color',colors(iH,:)*.8,'LineWidth',3)
    end
    %     new_x =  h.BinEdges(1:end-1) + diff(h.BinEdges(1:2))/2;
    % set(gca,'XTick',new_x)
end
% Some bug requires me to do the color thing again at the end. This is a
% work around.
for iH = 1:length(H)
    hh{iH}.EdgeColor = colors(iH,:);
end
axis tight
pubify_figure_axis
set(gca,'XMinorTick','off')
set(gca,'YMinorTick','off')
ylabel(normalization)
