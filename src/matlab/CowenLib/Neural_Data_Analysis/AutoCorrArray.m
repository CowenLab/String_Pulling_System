function [AC,x] = AutoCorrArray(TS,bin_size,window_duration,intervals)
% units are whatever units are in TS.
% if intervals are specified, then a new AC is made for each interval to
% produce a 3D matrix of AC.
% intervals are start and end times (cols) in units of TS.
% Cowen 2020 - first function of 2020
if nargin < 4
    intervals = [0 inf];
end
if ~isa(TS,'cell')
    tmp = TS; TS = [];
    TS{1} = tmp;
end
nbins = round(window_duration/bin_size);
AC = zeros(length(TS),nbins,Rows(intervals));
for iInterval = 1:Rows(intervals)
    TStmp = Restrict(TS,intervals(iInterval,:));
    for iC = 1:length(TStmp)
        if ~isempty(TStmp{iC})
            [AC(iC,:,iInterval),x] = AutoCorr(TStmp{iC},bin_size*10,nbins);
        else
            AC(iC,:,iInterval) = 0;
        end
    end
end
x = x/10;

if nargout == 0
    for iInterval = 1:Rows(intervals)
        figure
        imagesc(squeeze(AC(:,:,iInterval)))
    end
end