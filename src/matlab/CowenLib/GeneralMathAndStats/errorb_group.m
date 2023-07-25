function [O] = errorb_group(Mca,colors,useline,plot_points, CapSize, plot_bars)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen - plot error bars for a cell array of inputs...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Mca = cell array of matrices. All must have the same number of
%       columns.
%     colors - chose your collers an nx3 matrix. defaults to lines
%     useline - boolean - to use lines connecting points or not.
%
% OUTPUT: statistics for major comparisons.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2017 Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4
    plot_points = true;
end
if nargin < 5 || isempty(CapSize)
    CapSize = 18;
end
if nargin < 6
    plot_bars = false;
end
bar_width = .2;
MarkerSize = 22; % 16 is typical
fact = linspace(-.18, .18, length(Mca));
if nargin < 2 || isempty(colors)
    colors = lines(length(Mca));
end
if nargin < 3
    useline = false;
end

mn = []; se = [];
for ii = 1:length(Mca)
    mn(ii,:) = nanmean(Mca{ii});
    se(ii,:) = Sem(Mca{ii});
end
if Cols(Mca{1}) > 1
    plot(1:Cols(Mca{1}), mn,'w+')
else
    plot(1:length(Mca), mn,'w+')
end
hold on
h = [];
for iR = 1:size(mn,1)
    if length(Mca) == 2 && Cols(Mca{1}) == 1
        x = iR;
    else
        x = (1:size(mn,2))+fact(iR);
    end
    if useline
        plot(x, mn(iR,:),'Color',colors(iR,:),'LineWidth',2)
    end
    
    if plot_bars
        bar(x, mn(iR,:),'FaceColor',colors(iR,:),'BarWidth',bar_width);
    end
    if plot_points
        for ii = 1:Rows(Mca{iR})
            xx = x + (rand(size(x))-.5)*.07;
            plot(xx,Mca{iR}(ii,:),'.','MarkerSize',MarkerSize,'Color', colors(iR,:)*.5)
            
        end
    end
    %     h(iR,:) = errorb(x, mn(iR,:),
    %     se(iR,:),'Color',colors(iR,:),'BarWidth',4); %errorb sucks -
    %     inconsistent.
    if useline
        h(iR,:) = errorbar(x, mn(iR,:), se(iR,:),'Color',colors(iR,:),'CapSize',CapSize,'LineWidth',2);
    else
        h(iR,:) = errorbar(x, mn(iR,:), se(iR,:),'Color',colors(iR,:),'CapSize',CapSize,'LineWidth',2,'LineStyle','none');
    end
end
if plot_bars
    set(h,'Color','k')
end
if length(Mca) == 2 && Cols(Mca{1}) == 1
    set(gca,'XTick',[ 1 2])
end
a = axis;
a(1) = .5;
a(2) = max(x) + .5;
axis (a);
pubify_figure_axis

if nargout > 0
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do proper stats.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    D = [];   G1 = [];    G2 = [];
    for ii = 1:length(Mca)
        D = [D;Mca{ii}];
        G1 = [G1;repmat(1:Cols(Mca{ii}),Rows(Mca{ii}),1)];
        G2 = [G2;ones(size(Mca{ii}))*ii];
        O.n(ii) = Rows(Mca{ii});
        [~,O.ttest_zero_p(ii,:)] = ttest(Mca{ii}); % test if diff from zero.
        O.ttest_zero_p_bonf(ii,:) = bonf_holm(O.ttest_zero_p(ii,:));
    end
    %
    [O.p,O.tbl,O.stats] = anovan(D(:),{G1(:) G2(:)},'model','interaction','display','off');
    O.omega_square = omega_square(O.tbl{6,2}-O.tbl{5,2},O.tbl{6,3} - O.tbl{5,3},O.tbl{5,5},O.tbl{6,2});
    [~,O.tbl_no_interact,O.stats_no_interact] = anovan(D(:),{G1(:) G2(:)},'model','linear','display','off');
    O.omega_square_no_interact = omega_square(O.tbl_no_interact{5,2}-O.tbl_no_interact{4,2}, O.tbl_no_interact{5,3} - O.tbl_no_interact{4,3},O.tbl_no_interact{4,5},O.tbl_no_interact{5,2});
    % BIG ASSUMPTIONS:  INTEREACTION INVESTIGATED!! This reduces
    % the power to detect but if no interactions are part of the hypothesis
    % then be sure to specify no_interact. WARNING: This might give false
    % positives if done.
    O.multcomp1 = multcompare(O.stats,'display','off','CType','tukey-kramer');
    if Cols(Mca{1}) > 1
        O.multcomp2 = multcompare(O.stats,'Dimension',[1 2],'display','off','CType','tukey-kramer');
        O.multcomp3 = multcompare(O.stats,'Dimension',[2],'display','off','CType','tukey-kramer');
        IX = O.multcomp2(:,6) < 0.05;
        O.sigcomps2 = O.multcomp2(IX,:);
    end
    IX = O.multcomp1(:,6) < 0.05;
    O.sigcomps1 = O.multcomp1(IX,:);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Do it my way - limit tests to just paired columns. My way does not seem to
    % be any more powerful than the multcompare way even though
    % multocompare does EVERY comparison.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [~,O.ttest2_p] = ttest2(Mca{1}, Mca{2});
    O.ranksum_p = ranksum_matrix(Mca{1}, Mca{2});
    O.ttest2_p_bonfholm = bonf_holm(O.ttest2_p);
    O.ranksum_p_bonfholm = bonf_holm(O.ranksum_p);
    for ii = 1:Cols(Mca{1})
        [~, O.swtest_p(1,ii)] = swtest(Mca{1}(:,ii), 0.05);
        [~, O.swtest_p(2,ii)] = swtest(Mca{2}(:,ii), 0.05);
    end
    
end