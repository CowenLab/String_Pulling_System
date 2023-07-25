function [out_ah,r,g,H] = hist_groups(D,g,r,colors,inset_plot,options)
% function [out_ah,r,g,H] = hist_groups(D,g,r,colors,inset_plot,options)
% Histograms the data D (vector) belonging to groups g with nbins nbins.
% returns the range r for the xaxis
%
% INPUT
%  D, g = data vector, groups member vector
%   if D has multiple columns, it is presumed that each col is a group - in
%   this case, the g membership is ignored.
%   
%  r = range of the data to use: e.g. 0:1:30 or the number of bins.
%  colors = cell array of colors {'r','g'}
%  inset_plot = the data to plot in the inset. empty if you don't want
%  anyting.
%  options - a cell array of special options - e.g. {'probability'} would
%   rescale each distribution to sum to 1.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6
    options = [];
end
OFFSET_HISTOGRAMS = true;
ah = [];

if isempty(D)
    binsize = mean(diff(r));
    stairs(r-binsize/2,zeros(size(r)))
    return
end
if iscell(D)
    [D,g] = group_data(D);
end

if size(D,2) > 1
    % If column matrix passed in, assume each column is a group.
    g = ones(size(D));
    for ii = 1:size(D,2)
        g(:,ii) = ii;
    end
    D = D(:);
    g = g(:);
end

badix = find(isnan(sum(D',1)));
if ~isempty(badix)
    disp('Found nans in the data. Removing them');
    D(badix,:) = [];
    g(badix) = [];
end

if nargin < 5 || isempty(inset_plot)
    inset_plot = 'nothing_in_inset';
end

if nargin < 4 || isempty(colors)
    colors = lines(40);
end

    
if nargin < 3 || isempty(r)
    %r = linspace(min(D(:)), max(D(:)),20);
    [~,r] = hist(D(:),20);
end

if isscalar(r)
    [~,r] = hist(D(:),r);
end


if length(r) == 1
    % User specifies the number of bins.
    [~,r] = hist(D(:),r);
end

if size(D,1) ~= length(g)
    error('group and data are not of the same size')
end

rks = linspace(min(r), max(r), length(r)*100);
binsize = mean(diff(r));
ug = unique(g);

switch inset_plot
    case 'ksdensity'
        inset_data = zeros(length(ug),length(rks));
    case 'poisson'
        inset_data = zeros(length(ug),length(r));
    case 'nothing_in_inset'
        % Default - plot nothing - this is a filler.
        inset_data = zeros(length(ug),length(r));
end
ylab = '';
shift_amount = 0;
% bin_width = median(diff(r));

for iG = 1:length(ug)
    ix = find(g==ug(iG));
    if ~isempty (ix)
        [h]      = hist(D(ix),r);
        H{iG} = h;
        if OFFSET_HISTOGRAMS
            shift_amount = (iG-1)*median(diff(r))/6;
        end
        if ismember(options,'probability')
            h = h/sum(h); 
            ylab = 'p';
        end  
        if ismember(options,'probability_trapz')
            h = h./trapz(r,h); % This uses estimated trapezoidal AREA under the curve. 
            ylab = 'p';
            % This is robust if the bin sizes are not all the same. the commented out solution above works 
            % if they are the same.
            % For some reason this sometimes does give you probabiliteis
            % way over one if the bin size is very small. I am not sure
            % about this.
            %h ttp://stackoverflow.com/questions/5320677/how-to-normalize-a-histogram-in-matlab     
        end 
    
        
        if 0
            ah(iG) = barp(r,h,-binsize/2);
            set(ah(iG),'FaceAlpha',0.04)
            set(ah(iG),'FaceColor',colors(iG,:))
            set(ah(iG),'EdgeColor',colors(iG,:))
            set(ah(iG),'LineWidth',2)
        else
            % need to append one on the end.
            dr = median(diff(r));
            x = r-binsize/2 + shift_amount;
            % without doing this, you can get a dangling last bin.
            x(end+1) = x(end) + dr;
            h(end+1) = 0;
            % plot
            ah(iG)     = stairs(x,h);
            set(ah(iG),'Color',colors(iG,:));
            set(ah(iG),'LineWidth',3);
        end
        hold on
        switch inset_plot
            case 'ksdensity'
                inset_data(iG,:) = ksdensity(D(ix),rks);
                inset_data(iG,:) = inset_data(iG,:)/sum(inset_data(iG,:));
            case 'poisson'
                inset_data(iG,:) = poisspdf(r,poissfit(D(ix)));        
        end
    else
        stairs(r-binsize/2,zeros(size(r)))
    end
end
% Make the X axis tight but preserve the y axis
a = axis;
axis tight
a2 =axis;
a2(4) = a(4);
axis(a2);
ylabel(ylab)
if iscategorical(ug)
    legend(cellstr(ug))
    legend boxoff
end

if ~strcmp(inset_plot,'nothing_in_inset')
    for iG = 1:length(ug)
        ah = plot_in_quadrant(inset_data(iG,:),'upper_right',[.4 .4],colors{iG},@stairs);
        set(ah,'LineWidth',2);
    end
end
box off

if ismember(options,'errorbars')
   [ mn, se] = grpstats(D,g,{'nanmean' 'Sem'});
   a = axis;
   for iG = 1:length(mn)
       plot([mn(iG) mn(iG)],a(3:4),'Color',colors{iG})
       plot([mn(iG) mn(iG)]+se(iG),a(3:4),'Color',colors{iG},'LineStyle',':')
       plot([mn(iG) mn(iG)]-se(iG),a(3:4),'Color',colors{iG},'LineStyle',':')
   end
end


if nargout > 0
    out_ah = ah;
end