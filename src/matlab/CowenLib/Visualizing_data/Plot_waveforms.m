function ax = Plot_waveforms(W,clr)
%function ax = Plot_waveforms(W,clr)
%
% INPUT: npts x nch x nsamples waveform data.
%        color of the mean waveform and of the dots in the dot plot.
% OUTPUT: A waveform plot
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2010
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nCh = size(W,2);
nptsonwave = size(W,1);
nrecords = size(W,3);

if nargin < 2
    clr = 'k';
end

if nrecords > 700
    ix = round(linspace(1,nrecords,600));
else
    ix = 1:nrecords;
end

for iCh = 1:nCh
    ax(iCh) = subplot(1,nCh+1,iCh);
    w = squeeze(W(:,iCh,ix));
    E{iCh} = sqrt(sum(w.^2));
    plot(w)
    hold on
    plot(mean(w,2), 'LineWidth',5,'Color',clr)
    if iCh == 1
        title([num2str(iCh) ' ' num2str(nrecords) ' spikes' ])
    else
        title(num2str(iCh))
    end
    axis tight    
end

equalize_axes(ax)
ax(iCh+1) = subplot(1,nCh+1,nCh+1);
plot(E{1},E{2},'.','MarkerSize',1,'Color',clr)
axis tight; box off; axis square
title('Energy')
