function [inst_freq] = Instantaneous_Oscillatory_Frequency_Rajashree(LFP, sFreq)
% INPUT:
%  LFP = vector of the LFP data
%  sFreq - the sampling rate
% low_and_high - a vector of lenght = 2 that has the low and high cutoffs
% for the frequency estimation.
%
% OUTPUT:
%  For each point in LFP, inst_freq returns the best estimate of the
%  oscilaltory frequency at that point.
%
% Cowen 2022 - made some fixes.
% Cowen - note to Rajashree: 
% input y - fine for testing - but that broke the function as the inst
% freq is calculated in the original case on y and not LFP (the input to the function). I made the
% changes to fix this. See track changes in github
if nargin == 0
    % I often do this (nargin ==0) just to make it easy to test functions
    % with artificial data but not interfere with things when actual inputs
    % are supplied.
    sFreq = 1000;
    % for testing only
    t = 0:1/sFreq:2-1/sFreq;
    LFP = chirp(t,5,1,14);
end

z = hilbert(LFP);
inst_freq = sFreq/(2*pi)*diff(unwrap(angle(z)));
% Add a point to the end to adjust for the fact that the length of
% inst_freq is 1 less than the original LFP...
inst_freq(end+1) = inst_freq(end);

if nargout ==0
    % I assum that if no outputs are requested, the plot it out.
    figure
    plot(LFP);
    yyaxis right
    plot(inst_freq)
    xlabel('Time')
    ylabel('Hz')
    grid on
    title('Instantaneous Frequency')
end