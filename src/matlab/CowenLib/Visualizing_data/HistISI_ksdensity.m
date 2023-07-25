function [H, binsUsed] = HistISI_ksdensity(TS, varargin)
% A SMOOTHED ISI histogram plot.
% H = HistISI_ksdensity(TS, parameters)
% INPUTS:
%      TS = a single vector of timestamps (.1msec) or a ts object.
%
% OUTPUTS:
%      H = histogram of ISI
%      N = bin centers
%
% PARAMETERS:
%
% If no outputs are given, then plots the figure directly.
%
% Assumes TS is in seconds or timestamps!
% cowen 2003 -- overloaded version of adr-- this allows ts or timestamp
% vectors.
% ADR 1998
% version L5.3
% RELEASED as part of MClust 2.0
% See standard disclaimer in Contents.m
%
% Status: PROMOTED (Release version) 
% See documentation for copyright (owned by original authors) and warranties (none!).
% This code released as part of MClust 3.0.
% Version control M3.0.

%--------------------
if isa(TS, 'ts'); 
    TS = Data(TS);
end

%--------------------
% Assumes data is passed in in either seconds or timestamps
% if the maximum of TS is less than 10^7, then it assumes we need
% to convert to timestamps

if max(TS) < 1e7
    TS = TS*10000;
end

ISI = diff(TS/10) + eps;
if length(ISI) == 0
   warning('ISI contains no data!');
   ISI = 1;
end   
if ~isreal(log10(ISI))
   warning('ISI contains negative differences; log10(ISI) is complex.');
   complexISIs = 1;
else
   complexISIs = 0;
end

[H x] = ksdensity(log10(ISI));

%-------------------
if nargout == 0 
    plot(x,H)
%    plot(x,H*length(ISI)/100)
    hold on
    plot([0 0],[get(gca,'YLim')],'r:')
    xlabel('msec in powers of 10')
    %binsUsed = logspace(min(ISI),max(ISI),length(H));    plot(binsUsed, H);
    %plot(binsUsed,H)
end