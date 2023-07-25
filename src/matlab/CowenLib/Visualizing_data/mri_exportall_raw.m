% MRI_EXPORTALL_RAW  read a raw mri file and creates graphic files for all frontal slices
%              this file is a script which you will need to edit with your filename and
%              data dimensions.  All edit-worthy parameters are in the first section of code
%              these files can then be imported into powerpoint, making a very nice slice-viewer
%              for browsing the brain.
%
%              Scaling of the image is a bit tricky.  The display routine expects values
%              between 0 (black) and 1 (white).  Because matlab uses only 64 luminance values
%              you will need to specify a 'montage_divisor' which is simply the number that your
%              data will be divided by before display.  This lets you fit your data so that the 
%              interesting features are in the dynamic range of matlab graphics.
%              For example, if your data range from 
%              0 to 240000, you might want to use a divisor of 20000. 
%              Values over 20000 will then be converted to values above 1 and will
%              all be displayed at the value of 1 (white).
%              It is helpful to run a histogram on your raw luminosity values
%              to determine this scaling factor (e.g., hist(raw_data))

% EDITTABLE PARAMETERS
write_file = 0;
ap_file_root = fullfile(pwd,'ap');

dim_ml = 256;  % medial-lateral pixel dimension
dim_ap = 256;  % anterior-posterior pixel dimensions
dim_dv = 256;  % dorsal-ventral pixel dimensions
raw_datafile = '2dseq';

ap_start_slice = 1;
ap_end_slice = 243;

montage_divisor = 20000;  % the image is divided by this number before display
                           % since the display function requires values between 
                           % 0 and 1 use this number to scale your values so that
                           % most values fall within this range.  If in doubt, just set this
                           % to the maximum value in your data set.

% BEGING PROCESSING
if ~exist('raw_data', 'var')
    disp(['Reading data file ' raw_datafile]);
    fp = fopen(raw_datafile, 'r', 'ieee-le');
    raw_data = fread(fp, 'uint16');
    fclose(fp);
end

vol_data = reshape(raw_data, [dim_ml dim_ap dim_dv]);

for i = ap_start_slice:ap_end_slice
    cur_slice = squeeze(vol_data(:,i,:));
    image(64*cur_slice'/montage_divisor);
    %colormap(gray);
    axis equal;
    set(gca, 'xcolor', 'w');
    set(gca, 'ycolor', 'w');
    set(gca, 'color', 'none'); 
    set(gcf, 'color', 'k');
    text(3,dim_dv-5,['slice: ' num2str(i)], 'color', [1 1 1]);
    
    if ~write_file
       pause;
    end;
    
    if (write_file)
        set(gcf, 'units', 'pixels');
		set(gcf, 'position', [1 39 1400 927]);
        
        filename = [ap_file_root num2str(i, '%03d') '.png'];
        I = getframe(gcf);
        imwrite(I.cdata, filename);
    end

end

return;
