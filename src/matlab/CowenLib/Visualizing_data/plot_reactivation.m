function [f, h] = plot_reactivation(IN, title_string, session_numbers)
%function [f, h] = plot_reactivation(IN, title_string,session_numbers)
%
% IN = nx4 matrix of correlations, overlaps, biases, etc...
%      where first 3 cols are S1 M1S2 M2S3 and the final column 
%      is the data set id.
% title_string = a string you want on the title of the plot.
% session_numbers = for plotting - session number vector.
%
% cowen (2006)
% 
IN(:,1:3) = Fisher_Z_score(IN(:,1:3));
if nargin == 1
    title_string = '';
end
idx_id = size(IN,2);
sessions = unique(IN(:,idx_id));
if nargin < 3
    session_numbers = sessions;
end

goodidx = find(~isnan(IN(:,1)));
IN  = IN(goodidx,:);
PR1 = bootstrp(50, 'Partial_r', IN(:,[1 2 3]));
if idx_id == 6
    PR2 = bootstrp(50, 'Partial_r', IN(:,[1 4 5]));
else 
    PR2 = [];
end

clf
subplot(2,2,1)
if idx_id == 4
    mn = nanmean(PR1(:,4:6));
    Regress_compare(IN(:,[1 2]), IN(:,[3 2]))
    title ( [ title_string ' S1M1(b) S2M1(r)'])
    subplot(2,2,2)
    m = nanmean([PR1(:,1:3) ]);
    % NOTE: The std is really the standard ERROR in a bootstrap-- you
    %       don't divide by n bootstraps.
    s = nanstd([PR1(:,1:3)]); 
    bar(mn,.4,'c')
hold on
    bar(m)
    hold on
    e = errorbar(m,s,'.r');
%    set(e(2),'MarkerSize',.1);    
    lab = str2mat('S1M1_S2', 'S2M1_S1', 'S1S2_M1');
    
else
    mn = [nanmean(PR1(:,4:6)) nanmean(PR2(:,4:6))];
    Regress_compare(IN(:,[3 2]), IN(:,[5 4]))
    title ( [ title_string ' S2M1(b) S3M2(r)'])
    
    subplot(2,2,2)
    m = nanmean([PR1(:,1:3) PR2(:,1:3)]);
    % NOTE: The std is really the standard ERROR in a bootstrap-- you
    %       don't divide by n bootstraps.
    s = nanstd([PR1(:,1:3) PR2(:,1:3)]); 
    bar(mn,.4,'c')
    hold on
    bar(m)
    hold on
    m2 = nanmean([PR1(:,4:6) PR2(:,4:6)]);
    s2 = nanstd([PR1(:,4:6) PR2(:,4:6)]); 
    bar(m2,'MarkerSize',.4,'c')
    e = errorbar(m2,s2,'.c');
    set(e(2),'MarkerSize',.1);
    e = errorbar(m,s,'.r');
    set(e(2),'MarkerSize',.1);
    lab = str2mat('S1M1_S2', 'S2M1_S1', 'S1S2_M1','S1M2_S3', 'S3M2_S1', 'S1S3_M2');
    
end
hold on
axis tight
set(gca,'XTickLabel',lab);
set(gca,'FontSize',7);
title('r, b=partial,c=raw corr, BOOTSTRAPPED EV')
ylabel('r')


subplot(2,2,3:4)
PR1s = zeros(length(sessions),6)*nan;
PR2s = zeros(length(sessions),6)*nan;
for ii = 1:length(sessions)
    idx = find(IN(:,idx_id) == sessions(ii));
    PR1s(ii,:) = Partial_r(IN(idx,[1 2 3]));
    if idx_id == 6
        PR2s(ii,:) = Partial_r(IN(idx,[1 4 5]));
    end
end

bar(PR1s(:,2))
hold on 
bar(PR1s(:,1),.5,'c');
% The rBC - rAB
bar(PR1s(:,5) - PR1s(:,4),.2,'k');
if idx_id == 6
    bar(PR2s(:,2),.3,'m');
end

hold off
xlabel( 'Session')
set(gca,'XTick',1:length(sessions))
set(gca,'XTickLabel', sessions)
set(gca,'FontSize',5)
ylabel('r')
axis tight
a = axis;

mn1 = nanmean(PR1s);
sd1 = Sem(PR1s);
a = axis;
l = line([a(1) a(2)],[ mn1(2) mn1(2)]);
set(l,'linestyle','-')
set(l,'Color','b')
l = line([a(1) a(2)],[ mn1(2) + sd1(2) mn1(2) + sd1(2)]);
set(l,'linestyle',':')
set(l,'Color','b')
l = line([a(1) a(2)],[ mn1(2) - sd1(2) mn1(2) - sd1(2)]);
set(l,'linestyle',':')
set(l,'Color','b')

l = line([a(1) a(2)],[ mn1(1) mn1(1)]);
set(l,'linestyle','-')
set(l,'Color','c')
l = line([a(1) a(2)],[ mn1(1) + sd1(1) mn1(1) + sd1(1)]);
set(l,'linestyle',':')
set(l,'Color','c')
l = line([a(1) a(2)],[ mn1(1) - sd1(1) mn1(1) - sd1(1)]);
set(l,'linestyle',':')
set(l,'Color','c')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do T tests on the means to see if they are significantly %
% different.                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
str = [];
if idx_id == 6
    mn2 = nanmean(PR2s);
    se2 = Sem(PR2s);
    
    l = line([a(1) a(2)],[ mn2(2) mn2(2)]);
    set(l,'linestyle','-')
    set(l,'Color','m')
    if ttest2(PR1s(:,2),PR2s(:,2))
        str = [str ' (M1S2,M2S3 diff)'];
    else
        str = [str ' (M1S2,M2S3 ~diff)'];
    end
    if ttest2(PR2s(:,1),PR2s(:,2))
        str = [str ' (M1S1,M1S3 diff)'];
    else
        str = [str ' (M1S1,M1S3 ~diff)'];
    end
    
end

if ttest2(PR1s(:,1),PR1s(:,2))
    str = [str ' (S1M1,S2M1 diff)'];
else
    str = [str ' (S1M1,S2M1 ~diff)'];
end

h = title(['Sessions, b=S2M1_S1 c=S1M1_S2 m=S3M2_S1 k=rS2M1-rS1M1, Ttest:' str]);
set(h,'FontSize',8);
