function [H,X] = ActivityPETH(S, T, varargin)

% H = ActivityPETH(S, T, pararmeters)
%
% INPUTS
%   S = cell array of ts objects (spike times)
%   T = alignment times
%
% OUTPUTS
%   H = the histogram values for each timestep
%   X = the x axis (start:binsize:end) for the histogram
%  
% PARAMETERS
%   width = width of PETH (actually will be 2 * width + 1) (def 10000 ts = 1 sec)
%   binsize = size of bins (def 10 ts)


% ADR 1999
% Status UNTESTED
% Version 1.0
% modified by cowen: 8/2/00 to allow a variable amout of time before or after
% the stimulus onset.
%


StatusWarning('UNTESTED', 'ActivityPETH');
width = 10000; % 1 second
binsize = 10;  % 1 millisecond
Extract_varargin;

nAlignments = length(T);
nCells = length(S);

if length(width) == 2
  time_before_ts = width(1);
  time_after_ts  = width(2);
else
  time_before_ts = ceil(width/2);
  time_after_ts  = ceil(width/2);
end



X  = -time_before_ts:binsize:time_after_ts;
H  = zeros(size(X));

for iT = 1:nAlignments
   H0 = zeros(size(X));
   for iS = 1:nCells
      S0 = Restrict(S{iS}, T(iT) - time_before_ts, T(iT) + time_after_ts);
      if ~isempty(Data(S0))
         H0 = H0 + hist(Data(S0) - T(iT), X);
      end
   end
   H = H + H0;
   if nargout == 0
      plot(X/10000, H0, 'b'); hold on;
   end
end

if nargout == 0
   plot(X/10000, H, 'r', 'LineWidth', 2);
   hold off
end