function h = bar_many_groups(titles_ca,data_ca,xlabels_ca,plot_type);
% INPUT
%  titles_ca = cell array of string that describe each category
%  data_ca = cell array where each element is a vector of data associated
%     with each element in titles_ca.
%  grp_ix_to_data_caca = a cell array of cell arrays. The first element
%    describes the category (associated with the titles_ca) and the
%    subsequent elements in that category are teh indices to the datapoints
%    to categorize.
%  plot_type = error_bar (default)
%              box_plot 
%
% cowen
%   
nTitles = length(titles_ca);
if nargin < 4
    plot_type = 'mean';
end
for iTitle = 1:nTitles
    h(iTitle) = subplot(nTitles,1,iTitle);
    switch plot_type
        case 'mean'
            mn = []; se = [];
            for ii = 1:length(data_ca{iTitle})
                if ~isempty(data_ca{iTitle}{ii})
                    mn(ii) = nanmean(data_ca{iTitle}{ii});
                    se(ii) = Sem(data_ca{iTitle}{ii});
                else
                    mn(ii) = nan;
                    se(ii) = nan;
                end
            end
            errorbar([1:length(data_ca{iTitle})],mn,se)
        case 'box'
            [d,g] = group_data(data_ca{iTitle});
            boxplot(d,g,'notch','on')
    end
    title(titles_ca{iTitle})
    set(gca,'XTick',[1:length(data_ca{iTitle})])
    set(gca,'XTickLabel',xlabels_ca)
end
