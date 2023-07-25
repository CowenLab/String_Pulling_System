function Create_t_file_from_bounds(bounds_wavefile, bounds_tfile ,target_wavefile,output_tfile ,features)
% Given the min and max boundaries for the features in one file, apply them to another.
% 


FB = Determine_feature_bounds(bounds_wavefile, bounds_tfile, features);
timestamps = Apply_feature_bounds(target_wavefile, FB.mn, FB.mx, features);
% Write tfile.
timestamps = floor(timestamps/100); % Convert to the old precision, .1msec
[fp,msg] = fopen(output_tfile, 'wb', 'b');
if fp == -1; error('Could not open tfile'); end
WriteHeader(fp, 'T-file written by matlab');
fwrite(fp, timestamps, 'uint32');
fclose(fp);