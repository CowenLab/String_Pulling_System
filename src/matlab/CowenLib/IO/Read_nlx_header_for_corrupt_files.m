function H = Read_nlx_header_for_corrupt_files(fname)
% When the other header readers won't work - this gets the raw text.
% 
fp = fopen(fname,'r');
str = fgetl(fp)
H.FileName = fgetl(fp);
H.TimeOpened = fgetl(fp);
H.CreatedByMex = fgetl(fp);
H.NLX_Base_Class_Type = fgetl(fp);
H.RecordSize = fgetl(fp);
H.SamplingFrequency = fgetl(fp);
H.ADBitVolts = fgetl(fp);
H.ADMaxValue = fgetl(fp);
fclose(fp)

