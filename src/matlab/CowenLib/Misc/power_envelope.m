function [E F]= power_envelope(EEG,down_sFreq)
% Compute the power envelope (and instantaneous frequency) for a presumably filtered waveform.
% INPUT: EEG: 2 cols (time and data)
%        dow_sFreq - the downsampled frequency
% good for measuring theta power and frequency.
% ASSUMES TIMES IN 1/10000 sec.
% cowen.
aM = abs(EEG(:,2));
DF = diff(aM);
PeaksIdx  = find([DF; 0] < 0 & [0; DF] > 0);
TP = double([EEG(PeaksIdx,1) aM(PeaksIdx)]);
st = EEG(1,1); ed = EEG(end,1);
x = linspace(st,ed,round((ed/1e4-st/1e4)*down_sFreq));
y = interp1(TP(:,1),TP(:,2),x);
E = [x;y]';


if nargout == 0
    figure
    plot(EEG(:,1),EEG(:,2),'b',TP(:,1),TP(:,2),'g.',x,y,'r')
end
if nargout == 2
    % Compute the instantaneous frequency at each point as well.
    % This is just 1/(interval) and converted to seconds. I will smooth it
    % a bit.
    F = zeros(size(E));
    isi = TP(2,1)-TP(1,1);
    F(:,1) = x(:);
    % remember - this was peaks and troughs so divide by 2.
    tmp = interp1(TP(2:end,1)-isi/2,diff(TP(:,1)),x);
    F(:,2) = 5000./tmp(:);
end