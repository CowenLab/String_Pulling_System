function [coefEsts,y_out,modelFun,MSE] = SPEC_fit_1overf_func_to_PSD(x,y,x_out,startingVals)
% function [coefEsts,y_out,modelFun] = SPEC_fit_1overf_func_to_PSD(x,y,x_out,startingVals)
% Power Law fit.
% INPUT:
% x = frequencies
% y = psd values (log or not?)
% x_out = desired output frequencies for the fit.
% startingVals = enter some reasonable starting estimates for the function
%   as a 3 element vector according to p below...
%   p1 + p2*exp(-p3*(x));
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
if 0
%     NOTE: This is not 1/f but 1/exp(x). need to figure out what is up.
    y = [];  x = [];
    
    for ii = 1:10
        data = pinknoise(10000);
        y(:,ii) = pwelch(data);
        x(:,ii) = linspace(1,50,Rows(y))';
    end
    y = y';
    figure;
    plot(x(:),y(:))
    
    modelFun =  @(p,x) p(1) + (p(2) .* exp(-p(3).*x(:,1)));
    modelFun =  @(p,x) p(1) + (p(2) .* 1./(x(:,1).^p(3)));
    
    modelFun =  @(p,x) (p(1) .* exp(-p(2).*x(:,1)));
    modelFun =  @(p,x)  p(1) + p(2) .* 1./(x(:,1).*p(3));
    
    modelFun =  @(p,x) p(1) .* 1./(x(:,1).^p(2));
    x = x/max(x(:));
    coefEsts = nlinfit(x(:), y(:), modelFun, [min(y) 4 .01]);
    
    coefEsts = nlinfit(x(:), log(y(:)), modelFun, [max(y) 4 .01]);
    
    coefEsts = nlinfit(x(:), log(y(:)), modelFun, [1 .01]);
    
    coefEsts = nlinfit(x(:), y(:), modelFun, [max(y) 4 .01]);
    
    y_out = modelFun(coefEsts, x);
    
    
    figure
    plot(x,y,x,y_out)
    set(gca,'YScale','log')
    
end


if nargin == 0
    % demo if nothing is entered.
    x = 0:.2:200; % let's make it seem like we are going to 200 Hz.
    r = rand(1,length(x))*2; % noise - give the fit some challenge
    y = 100 + 5*exp(-.03*(x)+r); % the real equation.s
    
    startingVals = [min(y) 4 .01]; % guessing the initial estimates is the hard part. min(y) is a good guess for the first parameter.
    x_out = linspace(0,max(x),50);
end
if nargin < 4
     startingVals = [min(y) 4 .01];
end
if length(startingVals) < 2
    error('startingVals needs to have more elements')
end
GIX = ~isnan(y);
x = x(GIX); y = real(y(GIX));
% the 1/f equation.
modelFun =  @(p,x) p(1) + (p(2) .* exp(-p(3).*x));
if nargout < 4
    coefEsts = nlinfit(x(:), y(:), modelFun, startingVals);
else
    [coefEsts,~,~,~,MSE]  = nlinfit(x(:), y(:), modelFun, startingVals);
end
y_out = modelFun(coefEsts, x_out);

if nargout == 0
    plot(x,y)
    hold on
    plot(x_out,y_out,'ro-');
    set(gca,'YScale','log')
    % look at how close coefEsts matches the original coefficients!!!
    title(num2str(coefEsts))
    legend('original','exp fit')
    ylabel('10log10')
    xlabel('Hz')

    % for kicks, try this....
    %     figure
    %     loglog(x_out, y_out,'ro-');
    
end
