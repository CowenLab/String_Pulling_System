function INTAN_Filter_Amplifier_Channels(IF,cutoff,notch)
%Calls filter functions for all amplifier channels.

if nargin < 3
    notch = FALSE;
end

if nargin < 2;
    cutoff = 250;
end

if nargin < 1;
    IF = INTAN_Read_RHD_file;
end

sFreq = IF.frequency_parameters.amplifier_sample_rate;

for i = 1:numel(IF.amplifier_channels)
    curFile = strcat('amp-',IF.amplifier_channels(i).native_channel_name,'.dat');
    if (exist(curFile,'file'));
        highpass_dat_file(curFile,sFreq,cutoff)
        if notch
            notch_dat_file(curFile,sFreq,60,10);
        end
    end
end

end