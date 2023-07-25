function [H, mxwv, mnwv] = Lissajous_density(wv1,wv2);
%function [H, mxwv, mnwv] = Lissajous_density(wv1,wv2);
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
if isempty(wv1)
    H = [];
    return
end

n = size(wv1,1);
H = zeros(250);
mxwv = max([wv1(:);wv2(:)]);
mnwv = min([wv1(:);wv2(:)]);
%[r,c] = find(wv1);
[idx] = find(wv1);
H = ndhist([wv1(idx)'; wv2(idx)'],[250 250]',[mnwv mnwv ]',[mxwv mxwv]')';

if nargout == 0
   % s = sum(H');
   % H(find(s==0),:) = [];
   H = real(log(H));
   %H = Hsmooth(H); % Do this if you want it smoother.
   %H(find(H<-10)) = 0;
   imagesc(H);
   %caxis([min(H(:)) min([round(mean(H(:)) + 3*std(H(:))) maxc])])
   %colormap(1-gray)
   %axis off
   axis xy
    %contour(H,10) slow and doesn't doo much
end
