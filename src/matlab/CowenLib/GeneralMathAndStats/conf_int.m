function [mn,ci] = conf_int(D, type , p);
%function CI = confidence_intervals(D, type)
% Return a mean and a 2 row matrix of the upper, lower bounds of a
% distribution for each col in D.
% INPUT: type - type of confidence interval
%        p = p value or percent, depending on the type.
% cowen
if nargin < 2
    type = 'normal';
end
if isempty(D)
    ci = [];
    mn = [];
    return
end

mn = zeros(1,size(D,2));
ci = zeros(2,size(D,2));
switch type
    case 'normal'
        [mn,ci]= normci(D);
    case 'std'
        mn= nanmean(D,1);
        sd= nanstd(D);
        ci = [mn + sd; mn - sd];
    case 'trimmean'
        if nargin < 3
            p = 20; % percent of data to exclude.
        end
        
        mn = trimmean(D,p);
        se = Sem(D);
        ci(1,:) = mn + se;
        ci(2,:) = mn - se;
    case 'exp'
        if nargin < 3
            p = 0.05;
        end
        [mn,ci] = expfit(D,p);
    case 'notch'
        %        from boxplot - based on iqr/sqrt(n)
        pctiles = prctile(D,[25;50;75]);
        q1 = pctiles(1,:);
        med = pctiles(2,:);
        q3 = pctiles(3,:);
        n1 = med + 1.57*(q3-q1)/sqrt(size(D,1));
        n2 = med - 1.57*(q3-q1)/sqrt(size(D,1));
        if n1>q3, n1 = q3; end
        if n2<q1, n2 = q1; end
        mn = med;
        ci(1,:) = n1;
        ci(2,:) = n2;
    case 'poisson'
        if nargin < 3
            p = 0.05;
        end
        % 0.01 confidence intervals
        [mn,ci] = poissfit(D,p);
    otherwise
        error('incorrect type: conf_int')
end
