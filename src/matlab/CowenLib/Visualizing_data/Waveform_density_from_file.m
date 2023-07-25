function Waveform_density_from_file(fname,start_and_end_time)
if nargin == 1
    [wv] = Nlx2MatSE(fname,0,0,0,0,1,0);
else
    [wv] = Nlx2MatSE(fname,0,0,0,0,1,0, start_and_end_time(1),start_and_end_time(2));
end
if isempty(wv)
    disp('Empty file')
    return
end
wv = squeeze(wv)';
mn = mean (wv);
mny = mean (wv');
sd = std(wv);
[p,n,e] = fileparts(fname);
limit = 2000; % max number of points to bin at one time (to help with memory issues)
interpolate = 1;
figure
Waveform_density(wv,interpolate,limit);
title(['Aligned on peak' fname])
saveas(gcf,[n 'apeak'],'png')
figure
Waveform_density(wv-repmat(mny(:),1,32),interpolate,limit);
title(['Subtract Mean Voltage ' fname])
saveas(gcf,[n 'amean'],'png')

%figure
%Waveform_density_plot(wv.^2,interpolate,limit);
%title(['Squared ' fname ])
%saveas(gcf,[fname 'sqr'],'png')
