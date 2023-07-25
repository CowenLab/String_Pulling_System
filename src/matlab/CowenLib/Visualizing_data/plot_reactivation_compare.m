function [f, h, D] = plot_reactivation_compare(IN1, IN2, title_string,separate_figs)
% IN = 2 nx4 matrices of correlations, overlaps, biases, etc...
%      where first 3 cols are S1M1S2 M2S3 and the final column 
%      is the data set id.
% title_string = a string you want on the title of the plot.
% separate_figs = pass a 1 if you want separate figures for each plot.
%
%
%
textInterpreter = get(0,'DefaulttextInterpreter');
set(0,'DefaulttextInterpreter','tex')

if nargin <3
    title_string = '';
    separate_figs = 0;
end
if nargin <4
    separate_figs = 0;
end
if iscell(title_string)
    cat1 = title_string{2};
    cat2 = title_string{3};
    title_string = title_string{1};
else 
    cat1 = 'G1';
    cat2 = 'G2';
end
use_Rsq = 1; % do a ttest on the Rsq instead of the r.
nboot = 1000; % number of bootstraps.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wilson and McNaughton xy plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sessions1 = unique(IN1(:,4));
sessions2 = unique(IN2(:,4));
badidx = find(isnan(IN1(:,1)));

badidx = [badidx; find(isinf(IN1(:,1)))];
badidx = unique(badidx);
IN1(badidx,:) = [];
badidx = find(isnan(IN2(:,1)));

badidx = [badidx; find(isinf(IN2(:,1)))];
badidx = unique(badidx);

IN2(badidx,:) = [];

PR1 = bootstrp(nboot, 'Partial_r', IN1(:,[1 2 3]));
PR2 = bootstrp(nboot, 'Partial_r', IN2(:,[1 2 3]));

f = figure;
subplot_conditional(3,2,1,separate_figs);
Regress_compare(IN1(:,[3 2]), IN2(:,[3 2]));
title ( [ title_string ', ' cat1 ' (r) ' cat2 ' (g)'])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bootstrapped mean EV plots.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot_conditional(3,2,2,separate_figs);
% Mean really assumes it's normal. Not really the best measure.

m = nanmean([PR1(:,1:3) PR2(:,1:3)]);
% NOTE: The std is really the standard ERROR in a bootstrap-- you
%       don't divide by n bootstraps.
s = nanstd([PR1(:,1:3) PR2(:,1:3)]); 

bar(m)

%boxplot([PR1(:,1:3) PR2(:,1:3)],1)

hold on
m2 = nanmean([PR1(:,4:6) PR2(:,4:6)]);
s2 = nanstd([PR1(:,4:6) PR2(:,4:6)]); 
bar(m2,'MarkerSize',.4,'c')
e = errorbar(m2,s2,'.c');
set(e(2),'MarkerSize',.1);
e = errorbar(m,s,'.r');
set(e(2),'MarkerSize',.1);

axis tight
lab = str2mat('S1M1_S2', 'S2M1_S1', 'S1S2_M1','S1M1_S2','S2M1_S1','S1S2_M1');
set(gca,'XTickLabel',lab);
set(gca,'FontSize',7);
title(['r, b=partial,c=raw, nboot = ' num2str(nboot)])
xlabel([cat1 '                       ' cat2])
ylabel('r, bootstrapped')
grid on
if separate_figs
 % Do a special bootstrap plot, just for fun.
 figure
 r = [-.2:.01:1];
 

 h1 = hist(PR1(:,1),r);
 h2 = hist(PR1(:,2),r);
 h3 = hist(PR2(:,1),r);
 h4 = hist(PR2(:,2),r);

 ub1 = prctile(PR1(:,2),95);
 lb1 = prctile(PR1(:,2),5);
 ub2 = prctile(PR2(:,2),95);
 lb2 = prctile(PR2(:,2),5);

 plot(ub1,0,'g^')
  hold on
 plot(lb1,0,'g^')
 plot(ub2,0,'b^')
 plot(lb2,0,'b^')
 plot(r,h1,'r')
 hold on
 plot(r,h2,'g')
 plot(r,h3,'b')
 plot(r,h4,'m')
 
%  figure
% %  ub1 = prctile(PR1(:,2).^2*100,95);
% %  lb1 = prctile(PR1(:,2).^2*100,5);
% %  ub2 = prctile(PR2(:,2).^2*100,95);
% %  lb2 = prctile(PR2(:,2).^2*100,5);
%  bar (m)
%  hold on
%  %e = errorbar(m,[lb1 ub1 lb2 ub2],'.r');
%  e = errorbar(m,1.95*s,'.r');
%  set(e(2),'MarkerSize',.1);
%  axis tight
%  lab = str2mat('Pre High','Post High', 'Pre Low','Post Low');
%  set(gca,'XTickLabel',lab);
%  set(gca,'FontSize',16);
%  xlabel('High Vs. Low')
%  ylabel('EV')
figure
m = nanmean([PR1(:,1:2) PR2(:,1:2)].^2*100);
%med = nanmedian([PR1(:,1:2) PR2(:,1:2)].^2*100);
% NOTE: The std is really the standard ERROR in a bootstrap-- you
%       don't divide by n bootstraps. I did 2 checks for normality and the S2 distributions
%       came out normal. Interestingly, the S1 distributions did not. Because it came out normal, I 
%       will simply compare the 1.95std and see if they overlap. 
s = nanstd([PR1(:,1:2) PR2(:,1:2)].^2*100); 


 bar (m([2 4]))
 hold on
 e = errorbar(m([2 4]),1.95*s([2 4]),'.r');
 set(e(2),'MarkerSize',.1);
 axis tight
 frame_figure
 lab = str2mat('Post High','Post Low');
 set(gca,'XTickLabel',lab);
 set(gca,'FontSize',16);
 xlabel('High Vs. Low')
 ylabel('EV')
 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% individual, by session EV plots and ttest (unpaired which 
% is probably wrong.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot_conditional(3,2,3:4,separate_figs);
PR1s = zeros(length(sessions1),6)*nan;
PR2s = zeros(length(sessions2),6)*nan;
for ii = 1:length(sessions1)
    idx1 = find(IN1(:,4) == sessions1(ii));
    % Dont even bother with really small numbers of pair wise correlations
    % -- they only screw you up.
    if length(idx1)>30;
        PR1s(ii,:) = Partial_r(IN1(idx1,[1 2 3]));
        % In practice, bootstrapping by corr pair doesn't really change
        % the final value by much. However, bootstrapping by cell does.
        %PR1s(ii,:) = median(bootstrp(20, 'Partial_r', IN1(idx1,[1 2 3])));

    end
end

for ii = 1:length(sessions2)
    idx2 = find(IN2(:,4) == sessions2(ii));
    % Dont even bother with really small numbers -- they only screw you up.
    if length(idx2)>30;
        
        PR2s(ii,:) = Partial_r(IN2(idx2,[1 2 3]));
        
        % In practice, bootstrapping by corr pair doesn't really change
        % the final value by much. However, bootstrapping by cell does.
        %PR2s(ii,:) = median(bootstrp(20, 'Partial_r', IN2(idx2,[1 2 3])));

    end
end
bar([PR1s(:,2);PR2s(:,2)])
hold on 
h=bar([PR1s(:,4); PR2s(:,4)],.5,'c')

hold off
xlabel( 'Session', 'FontSize',8)
set(gca,'XTick',1:length([sessions1 ;sessions2]))
set(gca,'XTickLabel', [sessions1 ;sessions2])
set(gca,'FontSize',5)
ylabel('r')
axis tight
a = axis;

mn1 = nanmean(PR1s);
mn2 = nanmean(PR2s);
se1 = Sem(PR1s);
se2 = Sem(PR2s);
a = axis;
l = line([a(1) Rows(PR1s)+.5],[ mn1(2) mn1(2)]);
set(l,'linestyle','-')
set(l,'Color','r')

l = line([a(1) Rows(PR1s)+.5],[ mn1(2) + se1(2) mn1(2) + se1(2)]);
set(l,'linestyle',':')
set(l,'Color','r')
l = line([a(1) Rows(PR1s)+.5],[ mn1(2) - se1(2) mn1(2) - se1(2)]);
set(l,'linestyle',':')
set(l,'Color','r')


l = line([a(1) Rows(PR1s)],[ mn1(1) mn1(1)]);
set(l,'linestyle','-')
set(l,'Color','c')
l = line([Rows(PR1s)+.5 a(2)],[ mn2(2) mn2(2)]);
set(l,'linestyle','-')
set(l,'Color','g')
l = line([Rows(PR1s)+.5  a(2)],[ mn2(2) + se2(2) mn2(2) + se2(2)]);
set(l,'linestyle',':')
set(l,'Color','g')
l = line([Rows(PR1s)+.5  a(2)],[ mn2(2) - se2(2) mn2(2) - se2(2)]);
set(l,'linestyle',':')
set(l,'Color','g')

l = line([Rows(PR1s)+.5  a(2)],[ mn2(1) mn2(1)]);
set(l,'linestyle','-')
set(l,'Color','c')
o = nanmean(nanmean(PR1s));
disp(['Mean r: ' cat1 ' ' num2str(nanmean(PR1s(:,2))) ' ' cat2 ' ' num2str(nanmean(PR2s(:,2))) ])
if isnan(o)
    str = ['Not enough samples for individual analysis'];
else
    if ttest2(PR1s(:,1),PR1s(:,2))
        str = [cat1 ' M1S1 M1S2 diff'];
    else
        str = [cat1 ' M1S1 M1S2 ~diff'];
    end
end
o = nanmean(nanmean(PR2s));
if isnan(o)
    str = ['Not enough samples for individual analysis'];
else
    if ttest2(PR2s(:,1),PR2s(:,2))
        str = [cat2 ' M1S1 M1S2 diff'];
    else
        str = [cat2 ' M1S1 M1S2 ~diff'];
    end
    if ttest2(PR1s(:,2),PR2s(:,2))
        str = [str ' ' cat1 ' diff from ' cat2 ' M1S2'];
    else
        str = [str ' ' cat1 ' ~diff from ' cat2 ' M1S2'];
    end
end
title(['Sessions b=S2M1_S1 c=S1M1' str],'FontSize',8);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Paired plot and a paired ttest of the within trial differences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot_conditional(3,2,5,separate_figs);
if Rows(PR1s)~=Rows(PR2s)
    xlabel(['DATA NOT PAIRED WITHIN SESSION'],'FontSize',8)
    axis off
else
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Comparing r values -- cannot use R^2 in most cases as we often get 
    % negative values
    % esp for the bias measure-- this would make -.2 = .2 and we don't
    % want that even though statistically, R^2 is more correct.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if use_Rsq
        PR1s = PR1s.^2*100;
        PR2s = PR2s.^2*100;
        ylabel_str = 'EV';
    else 
        ylabel_str = 'r';
    end
    nr = Rows(PR1s);
    use_lines = 1;
    if use_lines
        l= line([ones(nr,1),ones(nr,1)*2]',[PR1s(:,2),PR2s(:,2)]');
        set(l,'Color',[.6 .6 .6])
        hold on
        plot (ones(nr,1),PR1s(:,2),'b.','MarkerSize',20)
        plot (ones(nr,1)*2,PR2s(:,2),'b.','MarkerSize',20)
  
        set(gca,'XTick',1:2)
        set(gca,'XTickLabel',{cat1,cat2})
        set(gca,'FontSize',16)
        axis tight
        a = axis;
        a(1) = a(1)-.2;
        a(2) = a(2)+.2;
        axis(a)
        ylabel_str = [ylabel_str ' Maze,Post|Pre' ];
    else
        boxplot(PR1s(:,2) - PR2s(:,2),1);
        xlabel(['Differnence Between ' cat1 ' and ' cat2])
        set(gca,'XTickLabel',[])
        ylabel_str = [ylabel_str ' '  cat1 ' - ' cat2];       
    end
    [h0,sig,ci] = ttest(PR1s(:,2) - PR2s(:,2));
    ylabel(ylabel_str,'FontSize',16)
    if h0 == 0
        str = sprintf('Not diff from 0, p=%0.3f, mn %s-%s %1.3f, sd %1.2f',sig,cat1,cat2,nanmean(PR1s(:,2)-PR2s(:,2)),std(PR1s(:,2)-PR2s(:,2)));
        title(str,'FontSize',8);
    else
        str = sprintf('Diff from 0, p=%0.3f, mn %s-%s %1.3f, sd %1.2f',sig,cat1,cat2,nanmean(PR1s(:,2)-PR2s(:,2)),std(PR1s(:,2)-PR2s(:,2)));
        title(str,'FontSize',8);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot_conditional(3,2,6,separate_figs);
[h1,r] = hist(PR1s(:,2),15);
[h2,r] = hist(PR2s(:,2),15);
plot(r,h1,'r');
hold on
plot(r,h2,'g');
title(['Hist of r POST,MAZE|PRE, ' cat1 ' (r), ' cat2 ' (g)'],'FontSize',8)
axis tight
xlabel('r')
ylabel('count')

if nargout == 3
    D.PR1   = PR1;
    D.PR2   = PR2;
    D.PR1s  = PR1s;
    D.PR2s  = PR2s;
    D.sessions1 = sessions1;
    D.sessions2 = sessions2;
    D.nboot = 1;
end
set(0,'DefaulttextInterpreter',textInterpreter)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the caller wants separate figures, provide them.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function h = subplot_conditional(a,b,c,d);
if d
    h = figure;
else
    h = subplot(a,b,c);
end
return