function [opt_ord, y_hat, err, mse] = cross_validation_order_est(x,y,order_range,filter_type,plot_it)
% Pass in some data in C to fit a polynomial to and this function, via
% cross validation, will find the optimal order estimate. 
%
% could also be used to find the optimal kernel size.
%
% TODO: Could have it intelligently stop when it reaches a trough and
% starts climbing up.
% 
%  Could fit a polynomial to the error curve to find the more precise
%  minimum order size.
if nargin <5 
    plot_it = 0;
end

nSamples = min([length(y), 40]); % number of leave one out's before estimating the MSE.
test_ix = floor(linspace(2,length(y)-1,nSamples));
mse = zeros(length(order_range),1);
e_est = zeros(nSamples,1);


switch lower(filter_type)
    case 'hanning'
        % THIS IS NOT WORKING
        xi = linspace(x(1),x(end), length(x));
        yi = interp1(x,y,xi);
        mn_y = mean(y); % serves as the filler value for the omitted data.
        for iO = 1:length(order_range)
            for iS = 1:nSamples
                y_train = y;
                y_train(test_ix(iS)) = mn_y;
                y_est = convn(y_train, hanning(order_range(iO))./sum(hanning(order_range(iO))),'same');
                % the y est in question will not exist since it is a nan so use the
                % point before and after to generate the estimate.
                e_est(iS) =  y(test_ix(iS)) - y_est(test_ix(iS));
            end
            mse(iO) = mean(e_est.^2);
        end
    case 'polynomial'
        warning off % polyfit spits out errors with repeated values.
        for iO = 1:length(order_range)
            for iS = 1:nSamples
                train_ix = setdiff(1:length(y),test_ix(iS));
                p = polyfit(x(train_ix),y(train_ix),order_range(iO));
                y_est = polyval(p,x(test_ix(iS)));
                % the y est in question will not exist since it is a nan so use the
                % point before and after to generate the estimate.
                e_est(iS) = y(test_ix(iS)) - y_est ;
            end
            mse(iO) = mean(e_est.^2);
        end
        warning on
    otherwise
        error('whoops')
end
[mn,ix]= min(mse);
opt_ord = order_range(ix(1));
switch lower(filter_type)
    case 'hanning'
        y_hat = convn(y, hanning(opt_ord)./sum(hanning(opt_ord)),'same');
    case 'polynomial'
        
        [p,S,mu] = polyfit(x,y,opt_ord);
        [y_hat,err] = polyval(p,x,S,mu);
end

if plot_it == 1
    clf
    subplot(1,2,1)
    plot(order_range,mse)
    ylabel('mse')
    xlabel('order')
    subplot(1,2,2)
    plot(x,y,'.')
    hold on
    plot(x,y_hat,'r')
    plot(x,y_hat+err,'r.')
    plot(x,y_hat-err,'r.')
    ylabel('y')
    xlabel('x')
    title('Best Fit')
end