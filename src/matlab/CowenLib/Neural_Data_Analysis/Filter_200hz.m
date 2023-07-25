function Y = Filter_200hz(IN, lowlimit_fq, highlimit_fq, input_sFreq, output_sFreq, interpolate)
%function Y = Filter_200hz(IN, lowlimit_fq, highlimit_fq, input_sFreq, output_sFreq)
%
% Filter for ripple EEG
% 
% INPUT:
%        IN         = The EEG data to be filtered (a tsd object (if so, ts assumed to be .1msec 
%                     (legacy)) or a 2d matrix where col 1 = timestamps in SECONDS
%                     or, this can be a datapoint by time and data matrix where rows 
%                     are individual datapoints and col 1 is the time (in timestamps .1ms) and data.
%
%        lowlimit_fq   = lower limit of the band pass filter 
%                     (default is 100Hz)
%        highlimit_fq  = upper limit of the band pass filter 
%                     (default is 300Hz) Values above 400 Hz don't work
%     input_sFreq   = the sampling frequency of the IN_tsd.
%     output_sFreq  = the sampling frequency of the output.
%
% OUTPUT: 
%        Y          = tsd of filtered data that is subsampled if a tsd was passed in, otherwise
%                     it's a matrix where col 1 is time and col 2 is the data.
%
%

% cowen Wed Mar 24 14:08:41 1999
% cowen -- allows a matrix to be passed in instead of a tsd.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the raw eeg data out of the object and convert to familiar Hz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 6 
    interpolate = 1;
end
    error('Why are you using me? Use simple version.')
    
if isa(IN,'tsd')
    IN = [Range(IN,'ts')/10000 Data(IN)];
    send_tsd_out = 1;
else
    % Assume the data is in seconds.
    send_tsd_out = 0;
end
[n, x] = size(IN);
if interpolate
    % assume the input datapoints are NOT evenly spaced so interpolate the data.
    IN(:,2) = interp1(IN(:,1),IN(:,2),linspace(IN(1,1),IN(end,1),n)');
    IN(:,1) = linspace(IN(1,1),IN(end,1),n)';
end

if nargin < 5
  output_sFreq = 1000; % Hz. The desired sample frequency. 
end

% Set defaults and do some error checking
if nargin == 1
  % Default band pass
  lowlimit_fq  = 90; % Hz
  highlimit_fq = 280; % Hz
end

if highlimit_fq > 490
  error('Keep the upper limit below 490')
end

if nargin == 2
  error('You must pass in either one, three, or four parameters, not 2. Seek help.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If the input sample frequency is not specified, guess by using the
% median difference between datapoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 4
  input_sFreq = n/(IN(end,1) - IN(1,1));
  fprintf('Estimating input sample frequency to be : %f\n', input_sFreq)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F_Ny = output_sFreq/2;    % Hz. Use the output because data samlped at the output
                          % sfreq is what goes into filtfilt.
N = 8;                    % Order of the filter
passband = [lowlimit_fq/F_Ny highlimit_fq/F_Ny];  
ripple = .5;

%[B,A] = butter(N, passband);
[B,A] = cheby1(N, ripple, passband);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use filtfilt instead of filter because it corrects for phase
% distortion due to filtering. It runs through the filter twice.
% To save memory space I did not assign a separate value to the 
% output of filtfilt.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if send_tsd_out % If a tsd passed, pass one out, else, pass a matrix.
    Y = tsd(linspace(IN(1,1),IN(end,1),(IN(end,1) - IN(1,1))*output_sFreq)', ...
        filtfilt(B,A,interp1(IN(:,1),IN(:,2),linspace(IN(1,1),IN(end,1),(IN(end,1) - IN(1,1))*output_sFreq))'));
else
    Y = [   linspace(IN(1,1),IN(end,1),(IN(end,1) - IN(1,1))*output_sFreq)', ...
        filtfilt(B,A,interp1(IN(:,1),IN(:,2),linspace(IN(1,1),IN(end,1),(IN(end,1) - IN(1,1))*output_sFreq))')];
    %Y = [   linspace(IN(1,1),IN(end,1),(IN(end,1) - IN(1,1))*output_sFreq)', ...
    %    filtfilt(B,A,IN(:,2))];

end
