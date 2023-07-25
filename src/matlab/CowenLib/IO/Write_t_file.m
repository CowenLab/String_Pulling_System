function fp = Write_t_file(fn,TS)
% Save a tfile - presumes TS is in 10ths of msec and integers are probably
% best.
fp = fopen(fn, 'wb', 'b');
if (fp == -1)
    errordlg(['Could not open file"' fn '".']);
    keyboard;
end
WriteHeader(fp, 'T-file', 'Output from MClust''Time of spiking stored in timestamps (tenths of msecs)', 'as unsigned integer');
fwrite(fp, TS, 'uint32');
fclose(fp);