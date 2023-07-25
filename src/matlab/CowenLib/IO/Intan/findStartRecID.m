function startRecID = findStartRecID(time_file,sFreq)
%Finds the time-vector startRecID. This will always be within the first 30
%seconds, meaning that 1 million records is a safe window for 30000 samples
%per second.

if nargin < 2
    time_file = 'time.dat';
end

if nargin < 1
    IF = INTAN_Read_RHD_file();
    sFreq = IF.frequency_parameters.amplifier_sample_rate;
end

nRecs = sFreq * 31; %Takes first 31 seconds of trace, 30 is most that can precede 0.
infoFile = dir(time_file);
if infoFile.bytes/4 <nRecs
    nRecs = infoFile.bytes/4;
end
D = INTAN_Load_Time(time_file,sFreq,nRecs);
startRecID = (find(D == 0));
end