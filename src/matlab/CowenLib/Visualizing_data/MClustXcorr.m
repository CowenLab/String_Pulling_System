function [Y,xdim] = MClustXcorr(cl1, cl2, binsize_msec, xcorr_width_msec)
%function [Y,xdim] = MClustXcorr(cl1, cl2, binsize_msec, msec_each_side)
% INPUT: cluster number 1
%        cluster number 2
%        bin size of choice
%        msec on each side of the xcorr plot.
% OUTPUT:
%  an xcorr plot
%  the y and x dimensions of the plot.
%
% cowen
global MClust_TTData MClust_Clusters MClust_FeatureData

ts1 = Range(ExtractCluster(MClust_TTData, FindInCluster(MClust_Clusters{cl1}, MClust_FeatureData)),'ts');
ts2 = Range(ExtractCluster(MClust_TTData, FindInCluster(MClust_Clusters{cl2}, MClust_FeatureData)),'ts');
nbins = round(xcorr_width_msec/binsize_msec);
[Y, xdim] = CrossCorr(ts1, ts2, binsize_msec, nbins);
figure
plot(xdim,Y)
xlabel('msec')
ylabel('Count')
title(['XCorr ' num2str(cl1) ' Vs ' num2str(cl2) ]);


