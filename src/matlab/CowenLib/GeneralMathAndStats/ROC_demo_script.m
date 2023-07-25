%% ROC demonstration script: incomplete
% AUC area under the curve
% cowen
n = 50;
r1 = poissrnd(5,n,1);
r2 = poissrnd(8,n,1);
d = [r1;r2];
d2 = [r2;r1];
%d2 = [poissrnd(8,n,1);poissrnd(5,n,1)];
g = [zeros(n,1);ones(n,1)];
gr = g(randperm(length(g)));
gr2 = g(randperm(length(g)));

figure
subplot(2,2,1)
hist_groups(d,g); ylabel('Count')
legend('cat 1','cat 2')
pubify_figure_axis

[tp,fp]= roc_cawley05(g,d);
[tp2,fp2]= roc_cawley05(g,d2);
[tpr,fpr]= roc_cawley05(gr,d);
[tpr2,fpr2]= roc_cawley05(gr2,d);
%
subplot(2,2,2)
plot(fp,tp,'LineWidth',2)
hold on
plot(fpr,tpr,'g','LineWidth',2)
plot([0 1],[0 1],'r:','LineWidth',2)

ylabel('True Positive Rate')
xlabel('False Positive Rate')

legend('true','shuffle')

pubify_figure_axis
label_figure(mfilename)

%ROC(d,g)
subplot(2,2,3)
hist_groups(d2,g); ylabel('Count')
pubify_figure_axis

subplot(2,2,4)
plot(fp2,tp2,'LineWidth',2)
hold on
plot(fpr,tpr,'g','LineWidth',2)
plot([0 1],[0 1],'r:','LineWidth',2)
ylabel('True Positive Rate')
xlabel('False Positive Rate')
pubify_figure_axis
label_figure(mfilename)


%% Sanity check...
% This demonstrates that my measure of selectivity works regardless of the
% order at which you pass in the distribution.
n = 50;
r1 = poissrnd(5,n,1);
r2 = poissrnd(8,n,1);
%d = [r1;r2];
%d2 = [r2;r1];

[a1, p, ash1] = Auc_from_ranksum(r1, r2);
[a2, p, ash2] = Auc_from_ranksum(r2, r1);

auc1 = abs(a1-.5) - abs(ash1-.5);
auc2 = abs(a2-.5) - abs(ash1-.5);
