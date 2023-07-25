function o = calc_react_from_struct(r,plotit,title_string)
% Expects the following structure in r
%     rBC_A: [1xn double]
%     rAB_C: [1xn double]
%     rAC_B: [1xn double]
%       rAB: [1xn double]
%       rBC: [1xn double]
%       rAC: [1xn double]
%  returns a structure of all the critical values calculated
%  
%  o.out_react_EV
%  o.mean_react_EV : reactivation based on the outliers.
if nargin == 1
    plotit = 0;
end
if nargin < 3
    title_string = '';
end
if length(r.rBC_A>1)
    o.the_range = -.3:.05:.8;
    [o.hBC_A,xdim] = hist(r.rBC_A,o.the_range);
    [o.hAB_C,xdim] = hist(r.rAB_C,o.the_range);
    [o.hAC_B,xdim] = hist(r.rAC_B,o.the_range);
    [o.hBC,xdim] = hist(r.rBC,o.the_range);
    [o.hAB,xdim] = hist(r.rAB,o.the_range);
    [o.hAC,xdim] = hist(r.rAC,o.the_range);
end
% Compute the reactivation from mean of the vector in r

o.mean_react_EV = mean(r.rBC_A.^2) - mean(r.rAB_C.^2);

post_idx = find( abs(r.rBC_A.^2 - mean(r.rBC_A.^2)) > 2*std(r.rBC_A.^2));
pre_idx  = find( abs(r.rAB_C.^2 - mean(r.rAB_C.^2)) > 2*std(r.rAB_C.^2));
if isempty(pre_idx) , pre_idx  = 1:length(r.rBC_A);end
if isempty(post_idx), post_idx = 1:length(r.rBC_A);end

o.out_react_EV = mean(r.rBC_A(post_idx).^2) - mean(r.rAB_C(pre_idx).^2);



if plotit
    if length(r.rBC_A>1)
        
        subplot(2,2,1:2)
        plot(o.the_range, o.hBC_A,'r');
        hold on
        plot(o.the_range, o.hAB_C,'g');
        plot(o.the_range, o.hAC_B,'b');
        plot(o.the_range, o.hBC,'r:');
        plot(o.the_range, o.hAB,'g:');
        plot(o.the_range, o.hAC,'b:');
        l = legend('BC_A','AB_C','AC_B','BC','AB','AC');
        ylabel('count')
        xlabel('r')
        set(l,'FontSize',6)
        title([title_string 'r vals'])
    end
    subplot(2,2,3:4)
    e=error_bars(r.rAB_C(:).^2, r.rBC_A(:).^2, r.rAC_B(:).^2, o.mean_react_EV, o.out_react_EV);
    set(gca,'XTickLabel',{'AB_C','BC_A','AC_B','mean react','remove outlier'})
    title('EV measures (react = EVBC_A - EVAB_C)')
    ylabel('EV and Reactivation')
end