function Y = Filter_200hz_simple(IN, lowlimit_fq, highlimit_fq, input_sFreq)
%function Y = Filter_200hz(IN, lowlimit_fq, highlimit_fq, input_sFreq, output_sFreq)
%
% Filter for ripple EEG
% 
% INPUT:
%        IN         =  1 column or vector data.
%
%        lowlimit_fq   = lower limit of the band pass filter 
%                     (default is 100Hz)
%        highlimit_fq  = upper limit of the band pass filter 
%                     (default is 300Hz) Values above 400 Hz don't work
%     input_sFreq   = the sampling frequency of IN ASSUMES EVENLY SPACED..
%
% OUTPUT: 
%        Y          = Filtered data.
%
%
if isempty(lowlimit_fq)
    lowlimit_fq = 120;
end
if isempty(highlimit_fq)
    highlimit_fq = 240;
end
if nargin < 4
    error('Specify a sampling frequency')
end
if highlimit_fq > 490
    error('Keep the upper limit below 490')
end
N = 8;                    % Order of the filter. Was 4. 8 has a faster rolloff and higher does not seem to help much.
bpFilt = designfilt('bandpassiir','FilterOrder',N, ...
    'HalfPowerFrequency1',lowlimit_fq,'HalfPowerFrequency2',highlimit_fq, ...
    'SampleRate',input_sFreq,'DesignMethod' ,'butter');

% Cheby 1 with these parameters wigs on on the edges of the data.
% N = 20; %Cheby 1 with these parameters wigs on on the edges of the data.
% I am sure that tweaking it woudl work but I don't see the advantage over
% butterworth. Use fvtool to examine.
% 
% bpFilt = designfilt('bandpassiir','FilterOrder',N, ...
%     'PassbandFrequency1',lowlimit_fq,'PassbandFrequency2',highlimit_fq, ...
%     'SampleRate',input_sFreq,'DesignMethod' ,'cheby1','PassbandRipple', 1);


% fvtool(bpFilt,'Analysis','freq')

Y = filtfilt(bpFilt,IN);


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Filter parameters: Old way. Now doing this with filtdesign. Makes
% checking easier. slightly slower upfront but not bad.
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% F_Ny = input_sFreq/2;    % Hz. Use the output because data samlped at the output
%                           % sfreq is what goes into filtfilt.
% passband = [lowlimit_fq/F_Ny highlimit_fq/F_Ny];  
% ripple = .5;
% [B,A] = cheby1(N, ripple, passband);
% 
% Y2 = filtfilt(B,A,IN);
