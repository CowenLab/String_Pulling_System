function nwrit = INTAN_Write_DAT_file(fname, D)
% Writes an int16 dat file.
% Cowen 2021
fp = fopen(fname,'w');
nwrit = fwrite(fp,D,'int16');
fclose(fp);

