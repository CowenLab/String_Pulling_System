function O = predict_choice_history_regression(LR)
LR_shuff = LR(randperm(length(LR)));
y = LR(3:end)';
x1 = LR(2:end-1)';
x2 = LR(1:end-2)';

O.logit.p_nminus1and2  = [nan nan];
O.logit.beta_1and2 = [nan nan];
try
    warning off
    [b,~,stats] = glmfit([x1 x2],y,'binomial','link','logit');
    warning on
    
    O.logit.p_nminus1and2 = stats.p(1:3);
    O.logit.beta_1and2 = b(1:3);
end
tbl = table(y, x1, x2);
mod = fitlm(tbl, 'y ~ x1 + x2');
O.mod = mod;
O.coef    = mod.Coefficients{:,1};
O.coef_p = mod.Coefficients{:,4};
%%%%%%%%%%%%%%%%%%
% Compare to shuffle.
%%%%%%%%%%%%%%%%%%
x1 = LR_shuff(2:end-1)';
x2 = LR_shuff(1:end-2)';
y = LR_shuff(3:end)';
tbl = table(y,x1,x2);
shuff_mod = fitlm(tbl,'y ~ x1 + x2');
O.shuff_mod = shuff_mod;
O.shuff_coef = shuff_mod.Coefficients{:,1};
O.shuff_coef_p = shuff_mod.Coefficients{:,4};