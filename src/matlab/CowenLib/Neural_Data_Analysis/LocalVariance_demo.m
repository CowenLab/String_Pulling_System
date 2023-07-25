function LocalVariance_demo( )
% Generate a number of ISI trains from different distributions...
%%
mean_rate_Hz = 20;
mean_ISI = 1/mean_rate_Hz;
mean_ISI_2 = mean_ISI * 1.4; % for the double exponential. 
n_spikes = 1850;
ISI = [];
ISI{1} = exprnd(mean_ISI,n_spikes,1);
tit{1} = sprintf('Exp %1.2f',mean_ISI);

ISI{2} = gamrnd(mean_ISI,mean_ISI_2,n_spikes,1);
tit{2} = sprintf('Gam %1.2f,%1.2f',mean_ISI,mean_ISI); % I could optimize so that the mean approaches the mean I need.
ISI{3} = random('InverseGaussian',mean_ISI,mean_ISI,n_spikes,1);
tit{3} = sprintf('inv gaus %1.2f,%1.2f',mean_ISI,mean_ISI);
ISI{4} = random('LogNormal',mean_ISI,mean_ISI,n_spikes,1);
tit{4} = sprintf('LogNormal %1.2f,%1.2f',mean_ISI,mean_ISI);
pd = fitdist(ISI{1},'Gamma');
ISI{5} = random(pd,n_spikes,1);
tit{5} = sprintf('GamFit %1.2f,%1.2f',pd.a,pd.b); % I could optimize so that the mean approaches the mean I need.
ISI{6} = random('LogNormal',mean_ISI*.2,mean_ISI*.4,n_spikes,1);
tit{6} = sprintf('LogNormal %1.2f,%1.2f',mean_ISI*.02,mean_ISI);
ISI{7} = exprnd(mean_ISI,n_spikes,1);
ISI{7} = ISI{7}.^2;
tit{7} = sprintf('Exp^2 %1.2f',mean_ISI);

ISI{8} = randmixexp(.75,mean_ISI,8*mean_ISI_2,n_spikes)';
tit{8} = sprintf('Mix Exp %1.2f',mean_ISI);

for ii = 1:length(ISI)
    % ensure mean rate...
    a = mean_ISI*n_spikes/sum(ISI{ii});
    ISI{ii} = ISI{ii}*a;
end

for ii = 1:length(ISI)
    txt = sprintf('%s| LV:%1.2f CV:%1.2f MN:%1.2f',tit{ii},LocalVariance(ISI{ii}),std(ISI{ii})/mean(ISI{ii}),1/mean(ISI{ii}));
    figure
    histogram(ISI{ii},60)
    title(txt)
end

%% let's test exp with different coefficients.
mean_rate_Hz = 20;
min_time_between_pulses = 0.005; % set to 0 for no constraint.
% min_time_between_pulses = 0; % set to 0 for no constraint.
dist = 'exponential'; coef = 0:.05:4; xlab = 'exponent from ISI^x';
dist = 'inverse gaussian';  coef = .0001:.01:.4 ; xlab = 'lambda';
%  dist = 'log normal'; coef =  0:.1:4; xlab = 'sigma';
% dist = 'mixed exp'; coef = 0:.05:4; xlab = 'b2';
 dist = 'gamma'; coef = 0:.01:2; xlab = 'shape';
lv = []; cv = []; lv_c = []; cv_c = [];
ISIs = zeros(length(coef),n_spikes);
for ii = 1:length(coef)
    switch dist
        case 'exponential'
            IS = exprnd(mean_ISI,n_spikes,1);
            IS = IS.^coef(ii);
        case 'inverse gaussian'
            IS = random('InverseGaussian',mean_ISI,coef(ii),n_spikes,1);        
        case 'log normal'
            IS = random('LogNormal',mean_ISI,coef(ii),n_spikes,1);
%             IS = random('LogNormal',coef(ii),mean_ISI,n_spikes,1);
        case 'mixed exp'
            IS = randmixexp(.5,mean_ISI,coef(ii)*mean_ISI,n_spikes)';
        case 'gamma'
            IS = gamrnd(coef(ii),mean_ISI,n_spikes,1);

    end
    a = (mean_ISI*n_spikes)/sum(IS);
    IS = IS*a;
    ISIs(ii,:)= IS;
    ISc = IS;
    ISc(IS<min_time_between_pulses) = min_time_between_pulses;
    
    % now insert an inter-stimulus interval!
    lv(ii) = LocalVariance(IS);
    lv_c(ii) = LocalVariance(ISc);
    cv(ii) = std(IS)/mean(IS);
    cv_c(ii) = std(ISc)/mean(ISc);
end
figure
plot(coef,lv,'o-'); hold on
plot(coef,lv_c,'o-')
ylabel('LV');xlabel(xlab)
yyaxis right 
plot(coef,cv,'s-'); hold on
plot(coef,cv_c,'p-')
ylabel('CV');
legend('lv','lv minISI','cv','cv minISI','Location','northwest')
title([ dist ' distribution ' num2str(mean_rate_Hz) 'Hz'])
pubify_figure_axis


figure
imagesc(ISIs);


%% % looks like only the second parameters matters for lognorml
m1 = .1:.1:20;
m2 = .1:.1:20;
lv2d = [];
for ii = 1:length(m1)
    for jj = 1:length(m2)
        IS = random('LogNormal',m1(ii),m2(jj),n_spikes,1);

        a = (mean_ISI*n_spikes)/sum(IS);
        IS = IS*a;
        lv2d(ii,jj) = LocalVariance(IS);


    end
end
figure
imagesc(m2,m1,lv2d)
axis xy
colorbar
pubify_figure_axis
