function [coefEsts,y_out,modelFun,MSE] = SPEC_fit_hyperbolic_func_to_PSD(x,y,x_out,startingVals)
% function [coefEsts,y_out,modelFun] = SPEC_fit_1overf_func_to_PSD(x,y,x_out,startingVals)
%
% INPUT:
% x = frequencies
% y = psd values
% x_out = desired output frequencies for the fit.
% startingVals = enter some reasonable starting estimates for the function
%   as a 3 element vector according to p below...
%   p(1) + (p(2) ./ (1 + x.*p(3)));
%
% OUTPUT:
%  coefEsts = a 3 element vector of the fitted coefficients.
%  y_out = the fitted psd values.
%  modelFun = the actual model function for your own use. Use like this...
%     y_out = modelFun(coefEsts, x_out);
%
% NOTE: Sometimes it may not converge. Then you may need better initial
% parameter estimates or just run again.
%
% Cowen 2016
if nargin == 0
    % demo if nothing is entered.
    x = 0:.2:200; % let's make it seem like we are going to 200 Hz.
    r = rand(1,length(x))*2; % noise - give the fit some challenge
    y = 100 + 5./(1 + 2*(x+r)); % the real equation.s
    startingVals = [min(y) 1 2]; % guessing the initial estimates is the hard part. min(y) is a good guess for the first parameter.
    x_out = linspace(0,max(x),50);
end
GIX = ~isnan(y);
x = x(GIX); y = real(y(GIX));

% the 1/(1 + x^v) equation.
modelFun =  @(p,x) p(1) + (p(2) ./ (1 + x.*p(3)));

if nargout < 4
    coefEsts = nlinfit(x(:), y(:), modelFun, startingVals);
else
    [coefEsts,~,~,~,MSE]  = nlinfit(x(:), y(:), modelFun, startingVals);
end
y_out = modelFun(coefEsts, x_out);

if nargout == 0
    plot(x,y,'k')
    hold on
    plot(x_out,y_out,'go-');
%     p = polyfit(x,y,13);
%     y1 = polyval(p,x);
%     plot(x_out, 10*log10(y1),'cx-');
%     
    % look at how close coefEsts matches the original coefficients!!!
    title(num2str(coefEsts))
    legend('original','hyp fit')
    xlabel('Hz')
    
    % for kicks, try this....
    %     figure
    %     loglog(x_out, y_out,'ro-');
    
end
