function Y = Filter_spikes(crdata, lowlimit, highlimit, input_sFreq, output_sFreq)
%
% Filter for ripple EEG
% 
% INPUT:
%        IN         = The EEG data to be filtered (a tsd object).
%        lowlimit   = lower limit of the band pass filter 
%                     (default is 100Hz)
%        highlimit  = upper limit of the band pass filter 
%                     (default is 300Hz) Values above 400 Hz don't work
%     input_sFreq   = the sampling frequency of the IN.
%     output_sFreq  = the sampling frequency of the output.
%
% OUTPUT: 
%        Y          = filtered data.
%
%function Y = Filter_200hz(IN, lowlimit, highlimit, input_sFreq)
disp('Replaced with Filter_for_spikes')
% 
% % cowen Wed Mar 24 14:08:41 1999
% if nargin == 5
%   sFreq = output_sFreq; 
% else
%   sFreq = 1000; % Hz. The desired sample frequency. 
% end
% 
% % Set defaults and do some error checking
% if nargin == 1
%   % Default band pass
%   lowlimit  = 300; % Hz
%   highlimit = 6000; % Hz
% end
% 
% if nargin == 2
%   error('You must pass in either one, three, or four parameters, not 2. Seek help.')
% end
% 
% 
% % Set the interval between records
% interval = floor(input_sFreq/sFreq);
% 
% % Filter parameters
% F_Ny    = sFreq/2;        % Hz
% lowcut  = lowlimit/F_Ny;  % Hz
% highcut = highlimit/F_Ny; % Hz
% N = 4;                    % Order of the filter
% passband = [lowcut highcut];  
% ripple = .5;
% 
% %[B,A] = butter(N, passband);
% [B,A] = cheby1(N, ripple, passband);
% %h = [abs(hh) abs(freqz(Bb,Ab,n)) abs(freqz(Bc,Ac,n))];
% % Use filtfilt instead of filter because it corrects for phase
% % distortion due to filtering. It runs through the filter twice.
% Y = filtfilt(B,A,crdata(1:interval:end));
% 
% 
