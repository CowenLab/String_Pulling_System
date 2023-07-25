function D = INTAN_Read_TRIG_file(fname)
% Future versions will allow you to restrict the data. Let's just keep it
% simple for now.
% Cowen 2014
fp = fopen(fname,'r');
D = fread(fp,'uint16');
fclose(fp);
