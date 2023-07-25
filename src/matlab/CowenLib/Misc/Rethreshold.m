function new_thresholds = Rethreshold(in_fname, out_fname, old_thresholds, new_thresholds)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% new_thresholds = Rethreshold(in_fname, out_fname, old_or_new_thresholds, new_thresholds)
%
% INPUT: A TT file to rethreshold
%        The destination file. (they can be the same)
%        old_thresholds = [ch1 ch2 ch3 ch4] the old thresholds (a vector)
%          IF old_thresholds
%        (optional) new_threhsolds. If empty or not used, then the waveforms 
%          will be plotted and the user will be allowed to graphically determine new 
%          thresholds. This is equivalent to calling RethresholdTT_nt(in_fname,out_fname,new_thresholds);
% OUTPUT: 
%         the new threhsolds.
%         TT file rethresholded
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cowen
if nargin <= 3
    new_thresholds = [];
end
n_channels = 4;

if isempty(new_thresholds)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Load in the first 80000 points
    % Actually, the best way is to load the data into a Trace object. (or mulitple trace objects)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [t,wv] = LoadTT0_nt(in_fname,[1 10000],4);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Display the waveforms and allow rethresholding on each channel. This thresholding is 
    % more advanced in that it allows you to specify windows around the data.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    for ch = 1:n_channels
        subplot(1,4,ch)
        W = squeeze(wv(1:20:end,ch,:));
        plot(W')
        a = axis;
        a(3) = -old_thresholds(ch)*8;
        a(4) = old_thresholds(ch)*8;
        axis(a);
        line([0 32],[old_thresholds(ch) old_thresholds(ch)])
        title(['CH: ' num2str(ch)])
    end
    disp('Press SPACE to adjust thresholds.')
    pause
    
    for ch = 1:n_channels
        subplot(1,4,ch)
        title('CHOOSE NEW THRESHOLD')
        [x,new_thresholds(ch)]=ginput(1);
        title(['CH: ' num2str(ch)])
    end
    disp('Press SPACE to rethreshold the TT file')
    pause
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Rethrehsold the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RethresholdTT_nt(in_fname,out_fname,new_thresholds);
