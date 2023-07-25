function D = INTAN_Read_DAT_file(fname, decimation_factor)
% Future versions will allow you to restrict the data. Let's just keep it
% simple for now.
% Cowen 2014
fp = fopen(fname,'r');
D = fread(fp,'int16');
fclose(fp);

if nargin > 1
    D = decimate(D,decimation_factor);
end
