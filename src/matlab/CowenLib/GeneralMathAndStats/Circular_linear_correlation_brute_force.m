function [out_rsq, out_r, out_pv, out_betas] = Circular_linear_correlation_brute_force(circ,lin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function [out_rsq out_r out_pv out_betas] =
% Circular_linear_correlation_brute_force(circ,lin)
%
% FOR PHASE PRECESSION ANALYSIS
%
% fits a regression line to the phase by time (or space or phase) plot. It
% rotates the plot (shifts phase up) until it minimizes the mse of the
% residuals. Returns the rsq, r, pvalu and betas. Presumes input is in
% radians.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2011.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RADIANS ONLY
lin = lin(:);
th = max(circ); % Threshold

tcirc = circ;

sh = 0.01; % If I was smart, I would chose the shift dynamically - find the next closest point and shift by an amount. Screw it. This works.
nSh = floor(2*pi/sh); % move a total of 2*pi shifts (360 degrees).
all_sh = zeros(1,nSh);
mse = zeros(nSh,1)*nan;
rsq = zeros(nSh,1)*nan;
pv = zeros(nSh,1)*nan;
all_b = zeros(nSh,2)*nan;
sh_count = 0;
for i=1:nSh
    IX = tcirc > th;
    if sum(IX) > 0 || i == 1
        
        tcirc(IX) = tcirc(IX) - 2*pi;
        % perform the regression...
        
        if 1
            [b,bint,resid,rint,stats] = regress(tcirc,[ones(size(lin)) lin]);
            mse(i) = mean(resid.^2);
            rsq(i) = stats(1);
            pv(i) = stats(3);
        else
            % Robust sometimes works well, but it's more unpredictable -
            % you never know what outliers it will throw out.
            [b,stats] = robustfit(tcirc, lin);
            mse(i) = mean(stats.resid.^2);
            rsq(i) = stats.coeffcorr(2).^2;
            pv(i) = stats.p(2);
            
        end
        
        all_b(i,:) = b';
        
        if nargout == 0
            figure(10102)
            clf
            plot(lin,tcirc,'.')
            lsline
            title(num2str(i))
            ax= axis;
            ax(3) = th - 2*pi;
            ax(4) = th;
            axis(ax)
            pause(.01)
        end
        
    else
        % Don't bother doing the regression if there was no need to shift.
        mse(i) = mse(i-1);
        rsq(i) = rsq(i-1);
        pv(i) = pv(i-1);
        all_b(i,:) =  all_b(i-1,:) ;
    end
    all_sh(i) = sh_count;
    sh_count = sh_count + sh;
    tcirc= tcirc + sh;
end


%
% for i=1:length(a)
%     % Phase shift circ
%     tcirc = asin(sin(circ/2 + a(i)));
%     % perform the regression...
%     [b,bint,r,rint,stats] = regress(tcirc,[ones(size(lin)) lin]);
%     mse(i) = mean(r.^2);
%     rsq(i) = stats(1);
%     pv(i) = stats(3);
%     all_b(i,:) = b';
%
%     plot(lin,tcirc,'.')
%     title(num2str(a(i)))
%     pause
% end
[m ix] = min(mse);
ix = ix(1);
out_rsq = rsq(ix);
out_pv = pv(ix);
out_betas = all_b(ix,:);
out_r = sqrt(rsq(ix));
if out_betas(2) < 0
    out_r = out_r * -1;
end

if nargout == 0
    figure
    subplot(2,2,1)
    plot(all_sh,mse);
    title('mse')
    subplot(2,2,2)
    plot(all_sh,rsq);
    title('rsq')
    subplot(2,2,3)
    plot(all_sh,pv);
    title('pv')
    subplot(2,2,4)
    plot(all_sh,all_b(:,2));
    title('all_b')
    
end