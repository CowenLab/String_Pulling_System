% MRI_MONTAGE  read a raw mri file and create tiled view of selected slices
%              this is a script you will need to edit.  Editable parameters are 
%              at the begining of the file.
%              Currently this is set up to create horizonal slices with 12 slices
%              shown in the composit image.  You set the upper and lower slices and it chooses
%              12 equally spaced slices between these limits.
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


write_file = 0;
dv_file_root = 'dv';

dim_ml = 256;  % medial-lateral pixel dimension
dim_ap = 256;  % anterior-posterior pixel dimensions
dim_dv = 256;  % dorsal-ventral pixel dimensions 
raw_datafile = '2dseq';

dv_start_slice = 15;
dv_end_slice = 90;

montage_divisor = 20000;  % the image is divided by this number before display
                           % since the display function requires values between 
                           % 0 and 1 use this number to scale your values so that
                           % most values fall within this range.  If in doubt, just set this
                           % to the maximum value in your data set.
if ~exist('raw_data', 'var')
    disp(['Reading data file ' raw_datafile]);
    fp = fopen(raw_datafile, 'r', 'ieee-le'); % The old files use big endian (be).
    raw_data = fread(fp, 'uint16');
    fclose(fp);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
motage_divisor = max(raw_data);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vol_data = reshape(raw_data, [dim_ml dim_ap dim_dv]);

D2 = zeros([dim_ml dim_ap 1 12]);

dv_slices = round([dv_start_slice:(dv_end_slice-dv_start_slice)/11:dv_end_slice]);

D2(:,:,1,:) = vol_data(:,:,dv_slices);
[h, tiled_image_data] = montage2(D2/montage_divisor);


if (write_file)
	filename = [dv_file_root '.png'];
	imwrite(tiled_image_data, filename, 'png');
end

return;


start_slice = 9;
end_slice = 112;
file_root = 'horiz';
count = 1;

for si = start_slice:12:end_slice
    cur_end = si+11;
    D2(:,:,1,:) = vol_data(:,:,si:cur_end);
    [h, tiled_image_data] = montage2(D2/montage_divisor);

	% trim down the range of values so we use the color map more efficiently
	% this clips out some high values that aren't carrying very much info
	upper_cut = 1.1;
	tiled_image_data(tiled_image_data>upper_cut) = upper_cut;
    filename = [file_root num2str(count) '.png'];
    imwrite(tiled_image_data, filename, 'png');
    count = count + 1;
end;

return;

Horiz_slices = 35:10:(35+10*5)

subplot(2,3,1);

imagesc(squeeze(vol_data(:,Horiz_slices(1),:))');
axis equal

subplot(2,3,2);
vol_data = reshape(raw_data, [256 256 256]);
imagesc(squeeze(vol_data(:,Horiz_slices(1),:))');
axis equal

subplot(2,3,3);
vol_data = reshape(raw_data, [256 256 256]);
imagesc(squeeze(vol_data(:,45,:))');
axis equal

subplot(2,3,4);
vol_data = reshape(raw_data, [256 256 256]);
imagesc(squeeze(vol_data(:,50,:))');
axis equal

subplot(2,3,5);
vol_data = reshape(raw_data, [256 256 256]);
imagesc(squeeze(vol_data(:,70,:))');
axis equal

subplot(2,3,6);
vol_data = reshape(raw_data, [256 256 256]);
imagesc(squeeze(vol_data(:,90,:))');
axis equal