function [OUT,T] = LK_Process_Paw_Digits(fname,th,median_win, PLOT_IT)
% function [OUT,T] = LK_Process_Paw_Digits(fname,th,median_win, PLOT_IT)
if nargin < 1
    fname = 'Time_Stamped_Coordinates.mat';
end
if nargin < 2
    th = .7; % I looked at the histogram and this looked reasonable but we could explore this parametrically.
end
if nargin < 3
    median_win = 5; % 50 - 60 Hz ish sampling - a bit faster since we are shifting by 1.
end
if nargin < 4
    PLOT_IT = false;
end
% load the file.
load(fname,'T')
msec_to_interpolate_over = 40;
OUT.Time_uSec = T.Time_uSec;
mean_interval_ms = median(diff(T.Time_uSec))/1e3;
% sFreq = 1/median(diff(T.Time_uSec)/1e6);
%%%%%%%%%%%%%%%%%%%%%%%
D = [T.L0_x T.L2_x T.L3_x T.L4_x T.L5_x ];
Lik = [T.L0_likelihood T.L2_likelihood T.L3_likelihood T.L4_likelihood T.L5_likelihood ];
OUT.Left_x = process_digits(D,Lik,th);
D = [T.L0_y T.L2_y T.L3_y T.L4_y T.L5_y ];
OUT.Left_y = process_digits(D,Lik,th);
%%%%%%%%%%%%%%%%%%%%%%%
D = [T.R0_x T.R2_x T.R3_x T.R4_x T.R5_x ];
Lik = [T.R0_likelihood T.R2_likelihood T.R3_likelihood T.R4_likelihood T.R5_likelihood ];
OUT.Right_x = process_digits(D,Lik,th);
D = [T.R0_y T.R2_y T.R3_y T.R4_y T.R5_y ];
OUT.Right_y = process_digits(D,Lik,th);
%%%%%%%%%%%%%%%%%%%%%%%
OUT.Nose_x = T.Nose_x;
OUT.Nose_y = T.Nose_y;
BIX = T.Nose_likelihood < th;
OUT.Nose_x(BIX) = nan;
OUT.Nose_y(BIX) = nan;
%%%%%%%%%%%%%%%%%%%%%%%

% filter
vbls = {'Nose_x' 'Nose_y' 'Left_x' 'Left_y' 'Right_x' 'Right_y' };
% given that it's sampling at > 250 Hz, then a 5 point median still results
% in ~50 Hz which should be more than enough. We could go to 4 points. I
% would not go bigger than 5.
n_pts_to_merge = ceil(msec_to_interpolate_over/mean_interval_ms);

for ii = 1:length(vbls)
    % movemedian gets rid of outlier points and some crazy jitter.
    OUT.(vbls{ii}) = movmedian(OUT.(vbls{ii}),median_win,'omitnan');
    % the movmean just smooths things a little more and avoids zero
    % derivatives.
    OUT.(vbls{ii}) = movmean(OUT.(vbls{ii}),median_win+2,'omitnan');
    % Fill in points that are say only 10ms 
    [C] = Count_contiguous(isnan(OUT.(vbls{ii})));
    IX = C<n_pts_to_merge & C > 0;
    GIX = ~isnan(OUT.(vbls{ii}));
    tmp = OUT.(vbls{ii});
    tmp(IX) = interp1(OUT.Time_uSec(GIX),OUT.(vbls{ii})(GIX),OUT.Time_uSec(IX),'spline');
    % need to do the following since spline can produce wacko values around
    % edges.
    tmp(tmp>max(OUT.(vbls{ii}))) = max(OUT.(vbls{ii}));
    tmp(tmp<min(OUT.(vbls{ii}))) = min(OUT.(vbls{ii}));
    OUT.(vbls{ii}) = tmp;
end

if PLOT_IT
    figure
    plot(OUT.Time_uSec/60e6,OUT.Left_x,OUT.Time_uSec/60e6,OUT.Left_y)
    hold on
    plot(OUT.Time_uSec/60e6,OUT.Right_x,OUT.Time_uSec/60e6,OUT.Right_y)
    plot(OUT.Time_uSec/60e6,OUT.Nose_x,OUT.Time_uSec/60e6,OUT.Nose_y)
    legend('lx','ly','rx','ry','nx','ny');
end

end

function v = process_digits(D,Lik,th)
%     histogram(max(Lik,[],2))
GOOD_PTS = max(Lik,[],2)>th;
D(Lik<th) = nan;
v = nan(size(D(:,1)));
v(GOOD_PTS,:) = nanmedian(D(GOOD_PTS,:),2);
end