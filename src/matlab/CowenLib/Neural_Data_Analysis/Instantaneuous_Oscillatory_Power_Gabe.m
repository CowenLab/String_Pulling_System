function [inst_power, power_time_stamps] = Instantaneuous_Oscillatory_Power_Gabe(LFP, sFreq, time_stamps)
% INPUT:
%  LFP = vector of the FILTERED-theta LFP data
%  sFreq - the sampling rate for the frequency estimation
%  time_stamps - table time stamps of LFP data


% OUTPUT:
%For each point in LFP, inst_power returns the best estimate of the
%  oscilaltory power at that point.
%power_time_stamps will give timestamps for each power point
%running alone will plot data


%%%%%%%%%%%%%%%%%%%% using Lindey's bump wavelet (cwt() method
if nargin == 0
    % add to make it easy to test functions
    % with artificial data but not interfere with things when actual inputs
    % are supplied.
    sFreq = 1000;
    % for testing only
    t = 0:1/sFreq:2-1/sFreq;
    LFP = chirp(t,5,1,14);
end

%cwt bump method:
cwt(LFP,"bump",sFreq);
caxis([2 10])
inst_power = cwt(LFP,"bump",sFreq);

% Add a point to the end to adjust for the fact that the length of
% inst_freq is 1 less than the original LFP...
if nargout ==0
end





%%%%%%%%Instantaneous Frequency of Complex Chirp Method

%fs = sFreq;
%t = time_stamps;
%x = exp(2j*pi*100*cos(2*pi*2*t)) + randn(size(t))/100;

%Compute and plot the Fourier synchrosqueezed transform of the signal. 
%time on the x-axis and the frequency on the y-axis:
%fsst(x,fs,'yaxis');
%[sst,f,tfs] = fsst(x,fs);
%fridge = tfridge(sst,f);

%hold on
%plot_freq = plot(t*1000,fridge/1000,'r')
%caxis([0 15])