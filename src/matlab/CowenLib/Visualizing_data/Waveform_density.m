function [H, xticks, yticks] = Waveform_density(wv,interpolate,limit,squeeze_it,xaxis);
% A 2D density plot of overlayed waveforms (log scaled).
%
%function [H, mxwv, mnwv] = Waveform_density_plot(wv,interpolate,limit);
%
% INPUT: a matrix of rows = time, col = waveform
%        interpolate- if it's >0, then the waveform density plot will be interpolated for better resolution.
%        limit- the max number of waveforms to histogram at one time-- if too large
%        you will run out of memory.
%        squeeze_it - default is 0 (do not squeeze) If squeezed, then the plot will be zoomed to only inclued +-3std of
%            the data.
% OUTPUT: if no argout, a density plot and a handle to it. Axes are scaled to have the same dims as the original.
%         if argout, the histogram is returned as well as the max and min values
%
% cowen 2/16/03

maxc = 100; % The maximum number of colors to show. 100 is about right -- more than that and the low
            % stuff disappears.
if isempty(wv)
    H = [];
    return
end

if nargin < 5
    xaxis = [];
end

if nargin < 2
    interpolate = 1;
    limit = 2000;
    squeeze_it = 0;
end
if nargin < 3
    limit = 2000;
    squeeze_it = 0;
end
if nargin < 4
    squeeze_it = 0;
end

if length(interpolate) > 1
    xlim = interpolate(1); % Number of points in x dim
    ylim = interpolate(2); % number of points in y dim
else
    xlim = 300;
    ylim = 700;
end
%
% Get rid of any nans.
non_nan_ix = find(~isnan(sum(wv')));
wv = wv(non_nan_ix,:);
pts = size(wv,2); % n points in the waveforms
n = size(wv,1);

H = zeros(ylim,xlim);

if squeeze_it
    mxwv = mean(wv(:)) + 6*std(wv(:));
    mnwv = mean(wv(:)) - 6*std(wv(:));
else
    mxwv = max(wv(:));
    mnwv = min(wv(:));
end

if sum(interpolate) > 0
    if n > limit
        nblocks = floor(n/limit);
        for ii = 1:nblocks 
            fprintf('.')
            idx = ((ii-1)*limit + 1):limit*ii;
            idx(idx>n) = [];
            % linear is fast, but not as pretty. Spline is about twice as
            % slow, but not as slow as cubic.
            wvi = interp1([1:pts]',wv(idx,:)',linspace(1,pts,xlim)','spline')';
            %wvi = interp1q([1:pts]',wv(idx,:)',linspace(1,pts,xlim)')'; --
            %R13 function supposed to be quicker than interp1, but it isn't -- actually a
            %little slower.
            [r,c] = find(wvi);
            [idx] = find(wvi);
            H = H + ndhist([c'; wvi(idx)'],[xlim ylim]',[1 mnwv ]',[xlim mxwv]')';
        end
    else
        wvi = interp1([1:pts]',wv',linspace(1,pts,xlim),'spline')';
        
        [r,c] = find(wvi);
        [idx] = find(wvi);
        H = ndhist([c'; wvi(idx)'],[xlim ylim]',[1 mnwv ]',[xlim mxwv]')';
    end
else
    xlim = pts;
    [idx] = find(wv);
    [r,c] = find(wv);
    H = ndhist([c'; wv(idx)'],[pts ylim]',[1 mnwv ]',[xlim mxwv]')';
end
%H = Hsmooth(H); % Do this if you want it smoother.
[r,c] = size(wv);
xticks = linspace(1, r,c);
yticks = linspace(mnwv,mxwv,r);

if nargout == 0
    % s = sum(H');
    % H(find(s==0),:) = [];
    if isempty(xaxis)
        xaxis = xticks;
    end
    
    HH = sqrt(sqrt(H+eps));
    %H2 = log(real(H));
    mn = min(H(find(H>-100)));
    %H(find(H < -100)) = mn;
    imagesc(xaxis,yticks,smooth2D(HH))
    axis xy
    ubound = min([round(mean(HH(:)) + 3*std(HH(:))) maxc]);
    lbound = min(HH(:));
    if ubound > lbound 
        caxis([lbound ubound])
    else
        caxis([lbound   1 + lbound*1.5])
    end
%    figure
%    mn = min(H2(find(H2>-100)));
%    H2(find(H2 < -100)) = mn;
%    imagesc(xticks,yticks,Hsmooth(H2))
%    axis xy
    
    %caxis([min(H(:)) min([round(mean(H(:)) + 3*std(H(:))) maxc])])
    %colormap(1-gray)
end

function S = smooth2D(H)
% 2d smoothing by convolving with a function -- a narrow pointy one in this case.
%c = [ .5 .5 .5];
r = [ 0.0225158185871862    -2.80653567739121e-018  0.202642367284676  0.5         0.202642367284676    -2.80653567739121e-018  0.0225158185871862];
c = [ 0.0225158185871862    -2.80653567739121e-018  0.202642367284676  0.5         0.202642367284676    -2.80653567739121e-018  0.0225158185871862];
S = conv2(r,c,H,'same'); % very similar to the filter2 command.
%S = H;
return
