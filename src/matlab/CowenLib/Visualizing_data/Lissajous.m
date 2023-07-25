function [h, h2] = Lissajous(wv, idx1, idx2)
%function [h, h2] = Lissajous(wv, idx1, idx2)
% Lissajous plots of the data in the 3D matrix wv.
% INPUT: wv: a nsamples x npoints matrix of waveform info.
%        idx1 and idx2 (optional) specifies the indices of the channels in the 3D matrix wv which
%          the caller would like to plot.
%
% OUTPUT: a plot and a handle to it.
%
% cowen
if nargin == 1
    do_all = 1;
else
    do_all = 0;
end

if do_all
    nch = size(wv,2);
    if size(wv,2) == 1
        disp('Only one channel, cannot do a lissajous')
        return
    end
    for rr = 1:nch
        for cc = rr+1:nch
            figure
            h = subplot(1,2,1);
            plot(squeeze(wv(:,rr,:))',squeeze(wv(:,cc,:))','.','MarkerSize',1)
            title([ num2str(rr) ' Vs ' num2str(cc)])
            axis square
            h2 = subplot(1,2,2);
            Lissajous_density(squeeze(wv(:,rr,:)),squeeze(wv(:,cc,:)));
            title([ num2str(rr) ' Vs ' num2str(cc)])
            axis square
        end
    end
else
    h = plot(squeeze(wv(:,idx1,:))',squeeze(wv(:,idx2,:))','.','MarkerSize',1);
    title([ num2str(rr) ' Vs ' num2str(cc)])
end
