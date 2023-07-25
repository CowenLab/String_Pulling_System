function [S,T] = sine_wave_by_duration_and_sFreq(fq,dur_sec,sFreq)
% function [S,T] = sine_wave_by_duration_and_sFreq(fq,dur_sec,sFreq)
%
% Create a sine wave of a given frequency for a given duration at the
% sampling rate determined by sFreq
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n_samps = dur_sec*sFreq;
n_cycles = dur_sec*fq;
end_rad = 2*pi*n_cycles;
trad = linspace(0,end_rad,n_samps);
S = sin(trad);
T = linspace(0,dur_sec,n_samps);

if nargout ==0
    figure
    plot(T,S)
end