function [ISImax, pks, flags] = calcISImax(bins, ISIhist, mpd, voidParamTh, ISITh)
% calcISImax.m
% by Valentina Pasquale - Italian Institute of Technology, March 2008
% %%
% calcISImax returns the value of ISI that optimally separates intra-burst
% ISI and inter-burst ISI (ISImax) (when present).
% It also returns the peaks detected in the ISI histogram and two flags
% telling if the channel is bursting (flags(1)) and/or if the minimum 
% between two peaks exists (flags(2)).
% %%
% ARGUMENTS:
% %%
% bins:     vector of x values for the logarithmic ISI histogram
% ISIhist:  vector of y values of the ISI histogram
% mpd:      minimum distance required between two peaks (e.g. 2), measured
%           in points.
% voidParamTh: minimum void parameter required for the two returned peaks to be well separated.
% ISITh:    maximum time window to look for the peak corresponding to intra-burst ISIs (e.g. 100
%           ms), measured in ms.
% %%
% RESULTS:
% %%
% ISImax:   value of ISI that optimally separates intra-burst ISIs and
%           out-burst ISIs (scalar)
% peaks:    vector (size n x 2) containing the coordinates of peaks in the
%           ISI histogram.
% flags:    vector (size 1 x 2):
%           - the first element is a flag for bursting activity 
%               --> flags(1) = 1 means the channel is likely to display 
%                   bursts; 
%               --> flags(1) = 0 means the channel is not bursting.
%           - the second element is a flag telling if the present
%               algorithm has detected a separation between two
%               peaks in the ISI histogram or not, according to the
%               specified voidParamTh.
%               --> flags(2) = 1 means the algorithm has detected two peaks
%                   separated by a minimum whose corresponding void parameter
%                   satisfies voidParamTh;
%               --> flags(2) = 0 means the algorithm has not detected two
%                   clear peaks or has not detected a sufficient separation
%                   between them.
% See also: V. Pasquale, S. Martinoia, M. Chiappalone "A self-adapting approach for the detection of bursts
% and network bursts in neuronal cultures", J. Comput. Neurosci., DOI
% 10.1007/s10827-009-0175-1.
%% initialize variables
ISImax = [];
flags = zeros(1,2);
pks = [];
%% check arguments' type
if ~isvector(bins)
    error('The first argument must be a 1-by-N or N-by-1 vector where N >= 1.')
else 
    bins = bins(:);   % column vector
end
if ~isvector(ISIhist)
    error('The second argument must be a 1-by-N or N-by-1 vector where N >= 1.')
else 
    ISIhist = ISIhist(:);   % column vector
end
if length(bins) ~= length(ISIhist)
    error('The first two arguments must be two vectors of the same size.')
end
if ~(isscalar(mpd) && ~(mod(mpd,1))) || mpd <= 0
    error('The third argument must be a positive scalar integer.')
end
if ~isscalar(voidParamTh) || voidParamTh <= 0 || voidParamTh >= 1
    error('The fourth argument must be a scalar value in the range [0,1].')
end
if ISITh <= 0 || ~(isscalar(ISITh) && ~(mod(ISITh,1)))
    error('The fifth argument must be a positive scalar integer.')
end
%% computation
% considering the decimal logarithm of x coordinate
% (in this way x-values are linearly spaced)
% xx -> bins
% yy --> ISI histogram
xx = bins;
yy = ISIhist;
if (~isempty(yy))
    [peaks,locs] = findpeaks(yy,'minpeakdistance',mpd);
    if ~isempty(peaks) && any(peaks)       % if there is at least one peak
        pks = [xx(locs) peaks(:)];
        numPeaks = size(pks,1);
        % index of peaks < 10^2 ms
        idxPeakIntraBurst = find(pks(:,1)<ISITh);
        % if there is more than one peak < 10^2 ms, it considers the
        % biggest one
        if(numel(idxPeakIntraBurst)>1)
            [maxPeakIntraBurst,idxMax] = max(pks(idxPeakIntraBurst,2));
            idxPeakIntraBurst = idxPeakIntraBurst(idxMax);
            % if there is no peak identified below 10^2 ms, the channel
            % is not analyzed
        else if(isempty(idxPeakIntraBurst))
                return;
            end
        end
        % we save the first peak's x- and y-coordinate
        y1 = pks(idxPeakIntraBurst,2);
        x1 = pks(idxPeakIntraBurst,1);
        locs1 = find(xx==x1);
        % this is the number of peaks found after the peak intra-burst
        % (i.e. the maximum peak between 0 and ISITh)
        numPeaksAfterBurst = numPeaks-idxPeakIntraBurst;
        %             %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if numPeaksAfterBurst == 0
            flags(1) = 1;   % the channel may be bursting, but the algo could not find two peaks
            flags(2) = 0;
            return;
        end
        if numPeaksAfterBurst >= 1
            yMin = zeros(numPeaksAfterBurst-1,1);
            idxMin = zeros(numPeaksAfterBurst-1,1);
            voidParameter = zeros(numPeaksAfterBurst-1,1);
            c = 0;
            for j = idxPeakIntraBurst:numPeaks
                c = c+1;
                x2 = pks(j,1);
                locs2 = find(xx==x2);
                y2 = pks(j,2);
                [yMin(c),tempIdxMin] = min(yy(locs1:locs2));
                idxMin(c) = tempIdxMin+locs1-1;
                % the void parameter is a measure of the degree of separation
                % between the two peaks by the minimum
                voidParameter(c) = 1-(yMin(c)/sqrt(y1.*y2));
            end
            idxMaxVoidParameter = find(voidParameter>=voidParamTh,1);
            % if there is no minimum that satisfies the threshold
            if isempty(idxMaxVoidParameter)
                flags(1) = 1;
                flags(2) = 0;
                return;
            end
            ISImax = xx(idxMin(idxMaxVoidParameter));
            flags = [1 1];
        end
    end
end