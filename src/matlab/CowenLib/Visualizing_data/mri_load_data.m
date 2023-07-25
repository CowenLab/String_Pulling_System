function vol_data = mri_load_data(datafile)
% Load the mri data and return the data matrix.

dim_ml = 256;  % medial-lateral pixel dimension
dim_ap = 256;  % anterior-posterior pixel dimensions
dim_dv = 256;  % dorsal-ventral pixel dimensions

disp(['Reading data file ' datafile]);
fp = fopen(datafile, 'r', 'ieee-le');
raw_data = fread(fp, 'uint16');
fclose(fp);
vol_data = reshape(raw_data, [dim_ml dim_ap dim_dv]);