function [B1, B2, errors] = fit_2_regressions(X,Y)
% Move along X, fitting a regression line to the separate halves of the 2
% distributions, stop when you find the minimum error.
%

% Convert the data to z scores for comparison
X = Z_scores(X);
Y = Z_scores(Y);
[X Y] = rotateXY(X,Y,-.08*pi);
%X = Z_scores(X);
%Y = Z_scores(Y);
%plot(X,Y,'.')

clf
ndeg = 1;
range_x = unique(X);
range_x = range_x(1:3:end);
errors = zeros(size(range_x))*nan;
errorsy = errors;

Blt = zeros(length(range_x),ndeg+1)*nan;
Brt = zeros(length(range_x),ndeg+1)*nan;

[b_all,stats_all]  = robustfit(X,Y);
for iX = 1:length(range_x')
    % split and regress
    left_ix = find(X<range_x(iX));
    right_ix = find(X>=range_x(iX));
    if length(left_ix) > 10 & length(right_ix) > 10
        % Fit to the regression.
        % further constrain to have a negative slope.
        %[P,S] = POLYFIT(X,Y,1)
        %[b,Bint,Res,Resint,stats_lt] = regress(Y,[ones(length(X),1) X]);
        %[b,stats_lt]  = polyfit(X(left_ix),Y(left_ix),ndeg);
        [b,stats_lt]  = robustfit(X(left_ix),Y(left_ix));
        b = b(end:-1:1); %polyval takes coefficients in reverse order (damn)
        
        %figure
        %plot(X(left_ix),Y(left_ix),'.')
        %hold on
        %plot(X(left_ix), polyval(b,X(left_ix)),'r.')
        
        error_lt(iX) = sum(abs(Y - polyval(b,X)));
        Blt(iX,:) = b';
        %lt_ols_s(iX) = stats_lt.ols_s;
        %lt_robust_s(iX) = stats_lt.robust_s;
        %
        [b,stats_rt]  = robustfit(X(right_ix),Y(right_ix));
        b = b(end:-1:1); %polyval takes coefficients in reverse order (damn)
        %[b,stats_rt]  = polyfit(X(right_ix),Y(right_ix),ndeg);        
        error_rt(iX) = sum(abs(Y - polyval(b,X)));
        Brt(iX,:) = b';
        %rt_ols_s(iX) = stats_rt.ols_s;
        %rt_robust_s(iX) = stats_rt.robust_s;
        % Compute the total error from fitting both of these lines to the
        % data.
        % we want the perpendicualr distance between points. Pdist may be
        % the thing we want.

        Xlt = mean(abs(X - polyval([Blt(iX,1)/Blt(iX,2) 1/Blt(iX,2) ]',Y)));
        Xrt = mean(abs(X - polyval([Brt(iX,1)/Brt(iX,2) 1/Brt(iX,2) ]',Y)));
        Ylt = mean(abs(Y - polyval(Blt(iX,:)',X)));
        Yrt = mean(abs(Y - polyval(Brt(iX,:)',X)));
%        Xrt = mean(abs(X - polyval(Brt(iX,:)',X)));
%        Xlt = mean(abs(X - polyval([1/Blt(iX,2) Blt(ix,1)/Blt(iX,2)]',Y)));
%        Xrt = mean(abs(X - polyval(Brt(iX,:)',X)));
        
        % Compute the summed error of fitting each model independently to the ENTIRE dataset. This seems like the right way. 
        errors(iX)  = mean([Xlt Xrt]);        
        errorsy(iX) = mean([Ylt Yrt]);
        % errors(iX) = (stats_lt.robust_s + stats_rt.robust_s)/stats_all.robust_s;
        % errors(iX) = stats_lt.robust_s / (stats_lt.robust_s + stats_rt.robust_s);
        % Plot the results.
        subplot(1,3,1:2)
        plot(X(left_ix),Y(left_ix),'b.');
        hold on
        plot(X(right_ix),Y(right_ix),'r.');
        axis square
        a = axis;
        plot(range_x, polyval(Blt(iX,:)',range_x),'b')
        plot(range_x, polyval(Brt(iX,:)',range_x),'r')
        plot(range_x(iX),a(3),'m^')
        axis(a);
        
        subplot(1,3,3)
        plot(log(errors))
        %hold on
        %plot(error_rt,'r')
        
        %plot(errors/max(errors),'b')
        %hold on
        %plot(errorsy/max(errorsy),'r')
        
        %pause(0.01)
        drawnow
    end
end
[min_e,min_ix] = nanmin(errors);
subplot(1,3,1:2)
plot(range_x, polyval(Blt(min_ix,:)',range_x),'b','LineWidth',6)
plot(range_x, polyval(Brt(min_ix,:)',range_x),'r','LineWidth',6)
a = axis;
plot(range_x(min_ix),a(3),'g^')
% find the categories.
%polyval([Blt(min_ix,1)/Blt(min_ix,2) 1/Blt(min_ix,2) ]',X)
%hold on
%plot(errorsy,'r')

