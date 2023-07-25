function INTAN_Remove_DC_From_Amplifier_Channels(IF)
%Calls the Remove_DC function for all amplifier channels.

if nargin == 0;
    IF = INTAN_Read_RHD_file;
end

for i = 1:numel(IF.amplifier_channels)
    curFile = strcat('amp-',IF.amplifier_channels(i).native_channel_name,'.dat');
    if (exist(curFile,'file'));
        Remove_DC(curFile);
    end
end

end