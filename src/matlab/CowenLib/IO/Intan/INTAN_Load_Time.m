function t = INTAN_Load_Time(tFile, sFreq, num_samples)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read in the timestamps - Intan creates a time.dat file. 
% Rauscher/Cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin <1
    tFile = 'time.dat';
end

if nargin <2
    IF = INTAN_Read_RHD_file;
    sFreq = IF.frequency_parameters.amplifier_sample_rate;
end

if nargin <3
   fileinfo = dir(tFile);
   if isempty(fileinfo)
       error([tFile ' not found'])
   end
   
   num_samples = fileinfo.bytes/4; % int32 = 4 bytes 
end
 
fid = fopen(tFile, 'r'); 
t = fread(fid, num_samples, 'uint32'); 
fclose(fid); 
t = t / sFreq; % sample rate from header file
t = t';

end