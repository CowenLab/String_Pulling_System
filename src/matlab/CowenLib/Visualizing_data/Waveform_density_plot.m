function [H, mxwv, mnwv] = Waveform_density_plot(wv,interpolate,limit);
%function h = Waveform_density_plot(wv,limit);
% INPUT: a matrix of rows = time, col = waveform
%        interpolate- if it's >0, then the waveform density plot will be interpolated for better resolution.
%        limit- the max number of waveforms to histogram at one time-- if too large
%        you will run out of memory.
% OUTPUT: if no argout, a density plot and a handle to it. 
%         if argout, the histogram is returned as well as the max and min values
%
% cowen
maxc = 100; % The maximum number of colors to show. 100 is about right -- more than that and the low
% stuff disappears.

if nargin < 2
    interpolate = 1;
    limit = 2000;
end
if nargin < 3
    limit = 2000;
end
n = size(wv,1);
H = zeros(1000,512);
mxwv = max(wv(:));
mnwv = min(wv(:));

if interpolate
    if n > limit
        nblocks = ceil(n/limit);
        for ii = 1:nblocks
            fprintf('.')
            idx = ((ii-1)*limit + 1):limit*ii;
            idx(find(idx>n)) = [];
            wvi = interp1([1:32]',wv(idx,:)',linspace(1,32,512),'spline')';
            [r,c] = find(wvi);
            [idx] = find(wvi);
            H = H + ndhist([c'; wvi(idx)'],[512 1000]',[1 mnwv ]',[512 mxwv]')';
        end
    else
        wvi = interp1([1:32]',wv',linspace(1,32,512),'spline')';
        [r,c] = find(wvi);
        [idx] = find(wvi);
        H = ndhist([c'; wvi(idx)'],[512 1000]',[1 mnwv ]',[512 mxwv]')';
    end
else
    [r,c] = find(wv);
    [idx] = find(wv);
    H = ndhist([c'; wv(idx)'],[32 1000]',[1 mnwv ]',[32 mxwv]')';
end

if nargout == 0
    s = sum(H');
    H(find(s==0),:) = [];
    imagesc(H);
    caxis([min(H(:)) min([round(mean(H(:)) + 3*std(H(:))) maxc])])
    %colormap(1-gray)
    axis off
    axis xy
    %figure 
    %contour(H,10) slow and doesn't doo much
end