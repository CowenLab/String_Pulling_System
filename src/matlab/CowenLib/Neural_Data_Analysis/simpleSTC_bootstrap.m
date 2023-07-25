function [STA, STC, md_up_lower_95, bootstat] = simpleSTC_bootstrap(Stim,sp,n,nboot)
% NOTE - simpleSTC alignes everyting so that only data at and BEFORE the
% spike time are shown: NOTHING after the spike is analyzed. If you want
% this, add something to the spike times.
% Cowen.
if nargin < 4
    nboot = 1000;
end
[STA,STC] = simpleSTC(Stim, sp, n);
[bootstat] = bootstrp(nboot,@simpleSTC,Stim, sp, n);
md_up_lower_95 = prctile(bootstat,[50,95,5]);

if nargout ==0 
    figure
    subplot(2,1,1)
    plot(STA,'LineWidth',3)
    hold on
    plot(md_up_lower_95(1,:),'r','LineWidth',3)
    plot(md_up_lower_95(2,:),'r')
    plot(md_up_lower_95(3,:),'r')
    subplot(2,1,2)
    STAn = STA'-md_up_lower_95(1,:);
    up = md_up_lower_95(2,:) - md_up_lower_95(1,:);
    down = md_up_lower_95(1,:) - md_up_lower_95(3,:);
    plot(STAn,'LineWidth',3)
    hold on
    plot(STAn + up,'r')
    plot(STAn - down,'r')
    plot_horiz_line_at_zero
end