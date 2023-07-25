function INTAN_Extract_Spikes(IF,sFreq,startrec,batch)

if nargin < 1
    IF = INTAN_Read_RHD_file;
end

if nargin < 2
    sFreq = IF.frequency_parameters.amplifier_sample_rate;
end

if nargin < 3
    startrec = findStartRecID('time.dat',sFreq)-1;
end
if nargin < 4
    batch = 'Batch2.txt';
end
%Append Files by multitrode (shell command, should be pretty fast) and call UMS2K Preparation Script (which calls
%UMS2K Script) 
for i = 1:(max([IF.amplifier_channels.multitrode_assignment]))
    goodmembers = find([IF.amplifier_channels.multitrode_assignment] == i);
    if (~isempty(goodmembers))
        numStr = 'Chnl';
        if (strfind(computer(),'PCWIN'))
            outStr = 'type ';
        else
            outStr = 'cat -u ';
        end
        for ii = 1:length(goodmembers)
            outStr = [outStr 'amp-' IF.amplifier_channels(goodmembers(ii)).native_channel_name '.dat '];
            numStr = [numStr '_' num2str(getIntanChannelNumber(IF,goodmembers(ii)))];
        end
        [~, deepestFolder, ~] = fileparts(pwd);
        outFileName = fullfile(pwd,['spk_' deepestFolder '_nCh_' num2str(length(goodmembers)) '_' numStr '.dat']);
        disp(['Tetrode File: ' outFileName]);
        outStr = strcat(outStr,'>',outFileName);
        system([outStr, '&' , 'exit']); %DOS command "type file1.dat file2.dat ...fileN.dat >outfile" (or "cat" shell command on unix system)
        %Call UMS2K Preparation Script (which calls UMS2K Script) 
        INTAN_UltraMegaSort2000_Prepare(outFileName,goodmembers,sFreq,startrec,batch);
    end
end

end