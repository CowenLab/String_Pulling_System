function [wcx, wcy, raster_data, smooth_raster_data] = find_lwc(pixel_data, frame_height, frame_width, gauss_width)

% FIND_LWC  find locally weighted center of rasterized data.
%           Used to extract most likely location of rat from
%           video tracking data
% find_lwc(pixel_data, frame_height, frame_width, gauss_width)
%           pixel_data = array of x,y pairs, one pair for each on pixel
%           frame_height, frame_width = dimensions in pixels of the full video frame
%           gauss_width = std. dev. of gaussian used for weighted mean computation (default = 4)
% Note about summing: each pixel pair in pixel_data
% is treated as an individual measurements for the purposes of finding
% the raster_data.  Hence, multiple occurence of a single pixel will be summed
% requires: conv_gauss2d

% DRE 9/24/04



if nargin<2
   frame_height = 480;
   frame_width = 640;
end;

if nargin<=3
   gauss_width = 4;
end;

raster_data = zeros(frame_height, frame_width);

for j = 1:size(pixel_data,1)
       line = pixel_data(j,:);
       % Note: to convert from (row, col) to unidimensional index number: (col-1)*num_of_rows + row	
       pixeli = (line(:,1)-1)*frame_height + line(:,2);
       if pixeli < 0
           pixeli = 1;
       end
       raster_data(pixeli) = raster_data(pixeli) + 1;
end

% smooth the data 
smooth_raster_data = conv_gauss2d(raster_data, gauss_width, gauss_width, 1,1,.1, 'same');
      
% find the peak density of on pixels
[maxval imaxx] = max(max(smooth_raster_data));
[maxval imaxy] = max(max(smooth_raster_data'));

wcx = imaxx;  
wcy = imaxy;  
