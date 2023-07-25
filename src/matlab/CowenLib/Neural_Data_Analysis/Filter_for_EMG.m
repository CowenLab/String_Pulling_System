function OUT = Filter_for_EMG(EMG,sFreq,filt_range)
% Filter for EMG.
% Cowen 2015
if nargin < 3
    filt_range = [50 500];
end

%
filter_type = 'iir';
switch filter_type
    case 'fir'
        bpFilt = designfilt('bandpassfir','FilterOrder',90, ...
            'CutoffFrequency1',filt_range(1),'CutoffFrequency2',filt_range(2), ...
            'SampleRate',sFreq);
    case 'iir'
        % This was faster and looked cleaner than the fir - at least for
        % the parameters specified above.
        bpFilt = designfilt('bandpassiir','FilterOrder',10, ...
            'HalfPowerFrequency1',filt_range(1),'HalfPowerFrequency2',filt_range(2), ...
            'SampleRate',sFreq);
end

OUT = filtfilt(bpFilt,EMG);

if nargout == 0
    % Diagnose.
    fvtool(bpFilt)
    figure
    plot(EMG)
    hold on
    plot(OUT,'r')
end