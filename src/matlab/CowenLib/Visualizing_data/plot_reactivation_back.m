function [f, h] = plot_reactivation(IN,title_string)
% IN = a nx4 or nx6 matrix of correlations, overlaps, biases, etc...
%      where first 3 or 5 cols are S1M1S2 M2S3 and the final column 
%      is the data set id.
%      IN can also be a cell array of length 2 in which each element is 
%      also nx4 and represents 2 values that need to be compared.
% title_string = a string you want on the title of the plot.

% 


if ~iscell(IN)
    [rr,cc] = size(IN);
    tmp = IN;
    clear IN;
    IN{1} = tmp;
end
id_idx = size(IN{1},2);

sessions = [];
for ii = 1:length(IN)
    goodidx = find(~isnan(IN{ii}(:,1)));
    IN{ii} = IN{ii}(goodidx,:);
    PR{ii} = bootstrp(100, 'Partial_r', IN{ii}(:,[1 2 3]));
    mnpr{ii} = nanmean(PR{ii});
    if size(IN{1},2)==6
        PR2{ii} = bootstrp(100, 'Partial_r', IN{ii}(:,[1 4 5]));
    end
    sessions{ii}= unique(IN{ii}(:,id_idx));
end

f = figure
subplot(2,2,1)
%Regress_compare(M(idx,[3 2]))
%title ( [ title_str 'M1S2, dt ' num2str(dt) 'ms'])
if size(IN{1},2) == 4
    % Multiple comparison
    if length(IN) > 1
        Regress_compare(IN{1}(:,[3 2]), IN{2}(:,[3 2]))
        title ( [ title_string ' IN 1 (r) IN 2 (g)'])
        
        subplot(2,2,2)
        Error_bars(PR{1}(:,1:3),PR{2}(:,1:3))
        hold on
        mn = [nanmean(PR{1}(:,4:6)) nanmean(PR{2}(:,4:6))];
        bar(mn,.4,'w')
        lab = str2mat('S1M1_S2', 'S2M1_S1', 'S1S2_M1','S1M1_S2', 'S2M1_S1', 'S1S2_M1');
    else
        Regress_compare(IN{1}(:,[1 2]), IN{1}(:,[3 2]))
        title ( [ title_string ' M1S1(r) M1S2(g)'])
        
        subplot(2,2,2)
        Error_bars(PR{1}(:,1:3))
        hold on
        mn = nanmean(PR{1}(:,4:6));
        bar(mn,.4,'w')
        lab = str2mat('S1M1_S2', 'S2M1_S1', 'S1S2_M1');
    end
    
else
    
    if length(IN) == 1
        % Compare S2 with S3 in the same dataset.
        Regress_compare(IN{1}(:,[3 2]), IN{1}(:,[5 4]))
        title ( [ title_string ' M1S2 (r) M2S3 (g)'])
        
        subplot(2,2,2)
        Error_bars([PR{1}(:,1:3) PR2{1}(:,1:3)])
        hold on
        mn = nanmean([PR{1}(:,4:6) PR2{1}(:,4:6)]);
        bar(mn,.4,'w')
        lab = str2mat('S1M1_S2', 'S2M1_S1', 'S1S2_M1','S1M2_S3', 'S3M2_S1', 'S1S3_M2');
    else
        error('Having more than 4 cols for the between group comparison is INVALID!')
    end
    
end

axis tight
set(gca,'XTickLabel',lab);
set(gca,'FontSize',8);
title('r, b=partial,w=raw corr')
ylabel('r')

mn = [];
ses_ids = [];


subplot(2,2,3:4)
if length(IN) == 1
    PR = zeros(length(sessions{1}),6);
else
    PR = zeros(length(sessions{1})+length(sessions{2}),6);
end

count = 1;
ses_ids = [];
for ii = 1:length(IN)
    G{ii} = zeros(length(sessions{ii}),6);
    
    if length(sessions{ii}>1)
        for a_ses = 1:length(sessions{ii})
            sidx = find(IN{ii}(:,id_idx) == sessions{ii}(a_ses));
            [PR(count,:)] = Partial_r(IN{ii}(sidx,[1 2 3]));
            G{ii}(a_ses,:) = PR(count,:);
            ses_ids(count) = sessions{ii}(a_ses);
            count = count + 1;
        end
    end
end

% IF NO GROUP COMPARISON: EASY WAY. MEAN BETWE
%cparam = {'c','b','m'}
%sizeparam= [.9 .5 .3];
bar(PR(:,2))
hold on 
h=bar(PR(:,1),.5,'c')

if size(IN{1}) == 6
    h = bar(PR(:,2),.3,'m');
    get(h)
end

if length(IN) == 1
    sessions{2} = [];
end

hold off
xlabel( 'Session')
set(gca,'XTick',1:length([sessions{1} sessions{2}]))
set(gca,'XTickLabel', [sessions{1} sessions{2}])
set(gca,'FontSize',4)
axis tight
a = axis;
% IF NO GROUP COMPARISON: EASY WAY. MEAN BETWE

if length(IN)==1
    
    mn = nanmean(PR)
    se = Sem(PR)
    l = line([a(1) a(2)],[ mn(2) mn(2)]);
    set(l,'linestyle','-')
    set(l,'Color','b')
    l = line([a(1) a(2)],[ mn(1) mn(1)]);
    set(l,'linestyle','-')
    set(l,'Color','c')
    if ttest2(PR(:,1),PR(:,2))
        str = ['S1S2 diff'];
    else
        str = ['S1S2 ~diff'];
    end
    
    if size(IN{1},2)==6
        mn2 = mean(PR2)
        se2 = Sem(PR2)
        l = line([a(1) a(2)],[ mn2(2) mn2(2)]);
        set(l,'Color','m')
        set(l,'linestyle','-')
        
        if ttest2(PR{1}(:,2),PR{1}(:,2))
            str = [str ' S2S3 diff'];
        else
            str = [str ' S2S3 ~diff'];
        end
        
        if ttest2(PR1(:,1),PR2(:,2))
            str = [str ' S1S3 diff'];
        else
            str = [str ' S1S3 ~diff'];
        end
    end
    t = title(['Sessions, c=S1M1_S2, b=S2M1_S1, m=S3M1_S1, ' str])
    set (t,'FontSize', 8)
else
    mn1 = nanmean(G{1})
    mn2 = nanmean(G{2})
    se1 = Sem(G{1})
    se2 = Sem(G{2})
    a = axis;
    l = line([a(1) Rows(G{1})],[ mn1(2) mn1(2)]);
    set(l,'linestyle','-')
    set(l,'Color','b')
    l = line([a(1) Rows(G{1})],[ mn1(1) mn1(1)]);
    set(l,'linestyle','-')
    set(l,'Color','c')
    l = line([Rows(G{1}) a(2)],[ mn1(2) mn1(2)]);
    set(l,'linestyle','-')
    set(l,'Color','b')
    l = line([Rows(G{1}) a(2)],[ mn1(1) mn1(1)]);
    set(l,'linestyle','-')
    set(l,'Color','c')
    
    if ttest2(PR{1}(:,1),PR{1}(:,2))
        str = ['G1 S1S2 diff'];
    else
        str = ['G1 S1S2 ~diff'];
    end
    
    if ttest2(PR{1}(:,2),PR{1}(:,2))
        str = [str 'G1 S2S3 diff'];
    else
        str = [str 'G1 S2S3 ~diff'];
    end
    
    if ttest2(PR{1}(:,2),PR{2}(:,2))
        str = [str ' G1 G2 M1S2 diff'];
    else
        str = [str ' G1 G2 M1S2 ~diff'];
    end
end


% Group comparison: HARD WAY.