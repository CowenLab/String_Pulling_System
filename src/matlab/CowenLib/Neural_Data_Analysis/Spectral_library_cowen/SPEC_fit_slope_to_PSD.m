function [betaloglog, betasemilog, pv, INFO] = SPEC_fit_slope_to_PSD(fq,power)
% INPUT: Assumes fq and power are not normalized by log. Raw spectral
% power. Assumes no nans in data. Returns nans if a nan. Each col is a PSD.
% pv = the coefficients for the NATURAL log for each point in frequency fq.
%  The fit is     plot(fq,exp(pv))
% Semilog line -- X axis is linear, Y axis is logarithmic
% Y=10^(Slope*X + Yintercept)
%
% Log-log line -- Both X and Y axes are logarithmic
% Y = 10^(slope*log(X) + Yintercept)
%
% Cowen 2018
% Cowen 2020: I just noticed this:
% https://aaronclauset.github.io/powerlaws/ along with code. The vals I get
% with this code are quite differnet from what I am getting and I think I
% trust the Santa Fe institute a bit more. see plfit() - I downloaded this
% toolbox.
% 
pv = [];
betaloglog = [];
betasemilog = [];
if min(size(power)) == 1
    power = power(:);
end
fq = fq(:);
if min(size(power)) > 1
    betaloglog = nan(2,Cols(power));
    betasemilog = nan(2,Cols(power));
    for iC = 1:Cols(power)
        [betaloglog(:,iC), betasemilog(:,iC), pv{iC}] =  SPEC_fit_slope_to_PSD(fq,power(:,iC));
    end
    return
end
betaloglog = nan;
betasemilog = nan;
% mdl = fitlm(log(fq),log(power),'linear');
% beta = mdl.Coefficients.Estimate(2);
if any(isnan(power))
    return
end
% ignore zeros
GIX = abs(power)>0;

[betaloglog,~,~,~,INFO.loglog] = regress(log(power(GIX)), [ones(length(fq(GIX)),1) log(fq(GIX))]);
[betasemilog,~,~,~,INFO.semilog] = regress(log(power(GIX)), [ones(length(fq(GIX)),1) fq(GIX)]);
pv = polyval(betasemilog(end:-1:1),fq);
% mdl = fitlm(log(fq),log(power),'linear'); % SLOOOW
% betasemilog = mdl.Coefficients.Estimate(2);
if nargout == 0
    
    figure
    clf
    subplot(1,4,1)
    plot(fq,power)
    hold on
    plot(fq,exp(pv))
    
    subplot(1,4,2)
    scatter(log(fq),power)
    lsline
    subplot(1,4,3)
    scatter(fq,log(power))
    lsline
    title(num2str(betasemilog))
    subplot(1,4,4)
    scatter(log(fq),log(power))
    lsline
    title(num2str(betaloglog))
    hold on
    plot(log(fq),log(power))
    
end
