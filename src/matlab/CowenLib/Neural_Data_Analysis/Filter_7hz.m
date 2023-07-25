function  Y = Filter_7hz(IN, lowlimit, highlimit, input_sFreq, output_sFreq)
%[Y, sFreq] = Filter_7hz(IN_tsd, lowlimit, highlimit, sFreq)
%
% Filter for Theta EEG (using a chebychev filter 4th order.)
% 
% INPUT:
%        IN         = The EEG data to be filtered (a tsd object).
%                     or, this can be a datapoint by time and data matrix where rows 
%                     are individual datapoints and col 1 is the time (in timestamps .1ms) and data.
%                     To conserve memory, you can also pass a single vector of data and 
%                     filter_7Hz will assume timestamps are in SECONDS unless a tsd is passed in. Then
%                       for legacy reasons, time is assumed to be in .1msec.
%
%        lowlimit   = lower limit of the band pass filter 
%                     (default is 100Hz)
%        highlimit  = upper limit of the band pass filter 
%                     (default is 300Hz) Values above 400 Hz don't work
%     input_sFreq   = the sampling frequency of the IN_tsd.
%     output_sFreq  = the sampling frequency of the output.
% 
% 
% OUTPUT: 
%        Y        = tsd if a tsd is passed in, a matrix if it is passed out.
%
% 
% cowen Wed Mar 24 14:08:41 1999
% cowen -- allows a matrix to be passed in instead of a tsd.
% 4/4/02 cowen -- memory is a big issue -- this routine is very inefficient with memory usage.
%       I am rewriting to make it more efficient and hopefully remain backward compatible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the raw eeg data out of the object and convert to familiar Hz.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 1
  % Default band pass
  lowlimit  = 6;  % Hz
  highlimit = 14; % Hz
end

if nargin < 4
    if isa(IN,'tsd')
        input_sFreq = (1/DT(IN))*10000; % Hz. The default sample frequency. 
    else
        dt = mean(diff(IN(:,1)));
        input_sFreq = (1/dt); % Hz. The default sample frequency. 
    end
end


if nargin < 5
  output_sFreq = 100; % Hz. The default sample frequency. 
end

if nargin < 6 
    interpolate = 1;
end


if highlimit > 50
  error('Keep the upper limit below 50. The filter cannot handle larger valuse')
end

if nargin == 2
  error('You must pass in either one, three, or more parameters, not 2. Seek help.')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filter parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
F_Ny    = output_sFreq/2;           % Hz
lowcut  = lowlimit/F_Ny;   % Hz
highcut = highlimit/F_Ny; % Hz
N = 4;                    % Order of the filter
passband = [lowcut highcut];  
ripple = .1;

%[Bb,Ab] = butter(N, passband);
[B,A] = cheby1(N, ripple, passband);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Use filtfilt instead of filter because it corrects for phase
% distortion due to filtering. It runs through the filter twice.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isa(IN,'tsd') % If a tsd passed, pass one out, else, pass a matrix.
    st = StartTime(IN);
    et = EndTime(IN);
    %nrecs = length(Range(IN,'ts'));
    n_out = ((et - st)/10000)*output_sFreq;

    Y  = tsd(linspace(st,et,n_out)', ...
         filtfilt(B,A,...
         interp1(Range(IN,'ts'), Data(IN), linspace(st,et,n_out)))');
     
else
    %IN(:,1) = IN(:,1)/10000;
    [n,c] = size(IN);
    c = 2;
    if c == 1
        %
        % This option saves a lot of memory -- it assumes the points are equally spaced.
        %  It's up to the user to figure out how the timestamps correspond to the datapoints.
        %  The input should be interpolated.
        %
        st = IN(1);
        et = IN(end);
    
        Y = filtfilt(B,A,IN);
        
    else
        st = IN(1,1);
        et = IN(end,1);
        n_out = (et - st)*output_sFreq;
        
        Y = [   linspace(st,et,n_out)', ...
                filtfilt(B,A,interp1(IN(:,1),IN(:,2),linspace(st,et,n_out)))'];
    end
    
end
