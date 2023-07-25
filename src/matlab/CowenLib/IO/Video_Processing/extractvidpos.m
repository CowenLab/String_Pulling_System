function pos_data = extractvidpos(infile, outfile, headstage_rad, inclusion_rad, check_flag, smooth_flag)

% EXTRACTVIDPOS takes an ascii file of tracker data and returns the rat's position 
% y = extractvidpos(infile, outfile, headstage_rad, inclusion_rad, check_flag, smooth_flag)
% headstage_rad - the radius of the headstage, in video frame pixels
% inclusion rad - radius of an imaginary circle drawn around the current position
%                 all pixels which fall outside this circle on the next frame are 
%                 discarded (this helps to control for aberant pixels coming on at
%                 random locations.
% output is a .PVD file which is an ascii file with the following columns:
% [Timestamp Xpos Ypos Velocity Direction]
% check_flag can be 0 (no checking), 1, 2, or 3 as detailed below.
% smooth_flag, if non-zero, causes the program to skip gaussian-window
% smoothing
% Velocity and Direction columns are presently just zeros, as this info has not been extracted.
% When we get to a headstage with a boom and rear light, the direction will
% be easier to compute.
% CHECK_FLAG DETAILS:
%     check_flag = 1:  Program starts with two figures showing you (on the left) all pixels on during the first 
%     five frames and (on the right) a smoothed version of this pixel display.  The estimated starting location
%     is shown with a green 'X'.  
%     Next comes the tracking display.  Here, the pixles for the previous, current, and following
%     frames is shown in blue, black and green, respectively.  Note that previous points have been
%     shifted forward and following points shifted backwards according to the estimated velocity 
%     of the rat.  The red circle indicates the best-fitting circle for the points displayed.  The blue
%     circle indicates the actual estimated position of the rat, taking into account its previous heading
%     and velocity.
%     check_flag = 2:  same as above except that when the rat is lost, you
%     will be shown the smoothed pixel display again and the new estimate
%     of the rat's location.
%     check_flag = 3:  same as above, plus if points are found outside the exclusion radius, 
%     the frame will freeze, displaying the active pixels and the inclusion radius, so you can see which
%     pixels are causing problems.  Hitting any key will continue with the fitting.
%
% HOW THE RAT IS FOUND IF LOST.  If there is no data
% during a particular period (i.e., the screen was competely blank for several time stamps) 
% the function will just skip these frames, no problem.  However, if, when the rat reappears on 
% the camera, its position has shifted so far that it is out of the inclusion circle centered on 
% its last known position, the tracker will lose the rat.  In this case, the program starts over again with a 
% locally weighted average to find the current position of the rat and then starts tracking from this new position 
% with the fitted circle.
%
% INFILE DETAILS:
%           infile is an .ascii video file, specifically:
%           it lists elements of a sparse matrix of all 'on' pixels.
%           Each line consists of (ts L RR GR BR RP GP BP X Y)
%           where ts is the timestamp of the frame,
%           L is luminance
%           RR GR BR is raw RGB
%           RP GP BP is pure RGB
%           X Y are coords of pixel.
%           e.g.,
%              494001080 0 0 0 0 1 0 0 217 129
%              494001080 0 0 0 0 1 0 0 218 129

if nargin<3
   headstage_rad = 9.5; % headstage radius, used by the circle-fitting algorithm
end
if nargin<5
   check_flag = 0;
end;
if nargin<6
   smooth_flag = 1;
end;

fid_in = fopen(infile);
if fid_in==-1
	error(['Could not open file: ' infile]);
end;
fseek(fid_in, 0, 'eof');
filesize_in = ftell(fid_in);
frewind(fid_in);


if check_flag
   set(gcf, 'doublebuffer', 'on');
else
   fid_out = fopen(outfile, 'w');
	if fid_out==-1
		error(['Could not open file: ' outfile]);
	end;
end;
	
timestamp = [];
last_ts = [];

hist_fac = .60;   % in determining the rats location, 
                  % this number determines how much the currently extracted position
                  % will be weighed relative to the estimate based on the rats last position
                  % and velocity.  Here's the code (see below)
                  % cur_xc = (1-hist_fac)*xc + hist_fac*(last_xc+dxc);
                  % cur_yc = (1-hist_fac)*yc + hist_fac*(last_yc+dyc);
                  % this factor essentially determines the amount of momentum the rat has
                  % larger values for this parameter mean more weight to the historical estimate
                  % and less weight for the current circle-fit estimate
vel_momentum = .75; % this value does the same thing for velocity
                         % larger values mean more weight to the previous historical estimate
                         % and less to current extracted value
                  

frame_height = 480;
frame_width = 640;
   
frame_x = 1:frame_width;
frame_y = 1:frame_height;

filereadblock =  300000;   % read this many characters from the file at a time
end_of_line_char = 10; % in present case, the character at the end of a line is a linefeed, char 10
end_of_file = 0;
filedata = [];
num_left = 0;
last_frame_data = [];
last_pixels = [];
last_pixels_shifted = [];
dxc = 0;  % change in x and y center with time (i.e., velocity)
dyc = 0;

% deal with header and blank lines
while ~feof(fid_in)
     fpos = ftell(fid_in);  % store current position in case we've read past header
     curline = fgetl(fid_in);
      
	if isempty(curline) | curline(1)=='%'
		continue; 
       else
          fseek(fid_in, fpos, -1);  % rewind file read position to end of header
          break
       end;
end;

pos_data = zeros(1000000, 5);  % pos data is [ts xpos ypos vel dir]
pos_data_counter = 1;
lost_ts = [];
first_frame_flag = 1;

while ~end_of_file
   
   start_fpos = ftell(fid_in);
	[newdata readcnt] = fread(fid_in, filereadblock-num_left, 'uchar');
   end_fpos = ftell(fid_in);

   disp(['Processing bytes ' num2str(start_fpos) ' to ' num2str(end_fpos) ' of ' num2str(filesize_in) '.']);
   if readcnt<filereadblock-num_left
		end_of_file = 1;
		%disp('DIAGNOSTICS: Reached end of file during read');
	end
	
	filedata = [filedata; newdata];
	s = char(filedata);
   num_read = max(find(s==end_of_line_char)); % find end of last complete line in string, we'll stop reading there
   s = s(1:num_read);
   
	[curdata count errmsg nexti] = sscanf(s, '%lf', [10 Inf]);
   
	curdata = curdata';  % this puts timestamps down the first column, like the file
	%disp(['DIAGNOSTICS: number of lines read: ' num2str(size(curdata, 1))]); 
   
   
	curdata = [last_frame_data; curdata];
	tslist = unique(curdata(:,1));
	
	last_ts = tslist(end);
	last_frame_data = curdata(curdata(:,1)==last_ts,:);  % cache this to add to processing stack next cycle
	
	if end_of_file
		last_ts_i = length(tslist);
	else 
		last_ts_i = length(tslist)-1;
	end
 
	% delete lines for pixel values that are greater than our supposed screen height or width
	curdata = curdata(curdata(:,9)<=frame_width,:); 
	curdata = curdata(curdata(:,10)<=frame_height,:);
	
	num_left = length(filedata) - num_read;
	%disp(['DIAGNOSTICS: read from string: ' ...
   %         num2str(num_read) '  remaining in string: ' num2str(num_left)]);
   filedata = filedata(num_read+1:end);   % remove all but the file data not read

   % FIND STARTING POINT ON INITIAL PASS via local weighted mean
   if first_frame_flag  
      
      lines = curdata(curdata(:,1)==tslist(1) | curdata(:,1)==tslist(2) | curdata(:,1)==tslist(3)...
                    | curdata(:,1)==tslist(4) | curdata(:,1)==tslist(5),:);
      lines_lum = lines(lines(:,2)==1,:);
      lines_red = lines(lines(:,3)==1,:);
      lines_green = lines(lines(:,4)==1,:);
      all_lines = [lines_lum; lines_red; lines_green];
                 
      [wcx, wcy, raster_data, smooth_raster_data] = find_lwc(all_lines(:,9:10), frame_height, frame_width);

      last_xc = wcx;
      last_yc = wcy;
            
      % plot the results
      if check_flag
         
         subplot(1,2,1)
         imagesc(raster_data);
         axis equal;
         axis xy
         axis([0 frame_width 0 frame_height]);
         hold on;
         plot(wcx, wcy, '+g');
         draw_circle([wcx wcy], inclusion_rad, 360, 'g');
         hold off;
         title('PRESS ANY KEY TO CONTINUE...')
         subplot(1,2,2);
         imagesc(smooth_raster_data);
         axis equal;
         axis xy;
         axis([0 frame_width 0 frame_height]);
         hold on;
         plot(wcx, wcy, '+g');
         draw_circle([wcx wcy], inclusion_rad, 360, 'g');
         hold off;
         pause; 
         clf;
      end;
      first_frame_flag = 0;   
   end
   
   % MAIN EXTRACTION LOOP
	for j = 1:last_ts_i
              
      cur_ts = tslist(j);
		cur_frame_data = curdata(curdata(:,1)==cur_ts,:);
		
		lum_lines = cur_frame_data(logical(cur_frame_data(:,2)),:);
		green_lines = cur_frame_data(logical(cur_frame_data(:,4)),:);
		red_lines = cur_frame_data(logical(cur_frame_data(:,3)),:);
					
		cur_pixels = [lum_lines(:,9:10); green_lines(:,9:10); red_lines(:,9:10)];
      
      % take care of the case where some pixels besides lum, green or red was the only thing on during 
      % a given timestamp.  In this case, cur_pixels will be an empty matrix.  We just ignore it and go to the next
      % frame with data in it.
      if size(cur_pixels,1)==0
         continue;
      end;
				
		if j~=last_ts_i
			next_ts = tslist(j+1);
			next_frame_data = curdata(curdata(:,1)==next_ts,:);
			
			lum_lines = next_frame_data(logical(next_frame_data(:,2)),:);
			green_lines = next_frame_data(logical(next_frame_data(:,4)),:);
			red_lines = next_frame_data(logical(next_frame_data(:,3)),:);
					
			next_pixels = [lum_lines(:,9:10); green_lines(:,9:10); red_lines(:,9:10)];
			% compensate for velocity and shift next pixels backward
		   next_pixels_shifted = [next_pixels(:,1)-dxc next_pixels(:,2)-dyc];
      else
         next_pixels_shifted = [];  % if this is the last ts in this batch, we can't find the next position
      end;
      
		% compensate for velocity and shift prev pixels forward
      if ~isempty(last_pixels)
         last_pixels_shifted = [last_pixels(:,1)+dxc last_pixels(:,2)+dyc];
		end;
      
      % combine all points together for finding fit
      fit_pixels = [last_pixels_shifted; cur_pixels; next_pixels_shifted];

      % exclude points that are outside of our local neighborhood defined by inclusion_rad
		[n m] = size(fit_pixels);
      dist = sqrt(sum(((fit_pixels - [last_xc*ones(n,1) last_yc*ones(n,1)]).^2)'))';
      keep_points_i = dist<inclusion_rad;
      num_excl = sum(~keep_points_i);
      num_incl = sum(keep_points_i);

      
      % Warn User that points are being excluded
      if num_excl>0
         disp([num2str(cur_ts, 11) ': excluded ' num2str(num_excl) ' points beyond inclusion_rad.']);
         
         if check_flag>=3
            
            draw_circle([last_xc last_yc], inclusion_rad, 360, 'g');
			   hold on;
			
			   if ~isempty(fit_pixels)
                plot(fit_pixels(:,1), fit_pixels(:,2), '.k');
            end
			   axis equal;
            axis([0 frame_width 0 frame_height]);
			   hold off;
             
			   text(5,15,num2str(cur_ts), 'color', [0 0 0]);
			   figure(gcf)
			   drawnow;
            pause;
         end
         
      end
      
      % Backup Plan: Find Rat Via Local Weighted Mean
      if num_excl>num_incl  % ok we might have a problem, better search again for the rat
         disp(['WARNING: ' num2str(cur_ts, 11) ', TOO MANY POINTS EXCLUDED.  USING LOCAL WEIGHTED MEAN TO RELOCALIZE RAT.']);

         % we use the weighted sum to find the largest set of on pixels
         % this will become our new estimate of current location for circle fitting
        
         [wcx, wcy, raster_data, smooth_raster_data] = find_lwc(cur_pixels, frame_height, frame_width);
         
         if check_flag>=2  % diagnostics
             subplot(1,2,1)
             imagesc(raster_data);
             axis equal;
             axis xy;
             axis([0 frame_width 0 frame_height]);
             hold on;
             plot(wcx, wcy, '+g');
             draw_circle([wcx wcy], inclusion_rad, 360, 'g');
             hold off;
             subplot(1,2,2);
             imagesc(smooth_raster_data);
             axis equal;
             axis xy;
             axis([0 frame_width 0 frame_height]);
             hold on;
             plot(wcx, wcy, '+g');
             draw_circle([wcx wcy], inclusion_rad, 360, 'g');
             hold off;
             pause; 
             clf;
         end     
         % now since we don't know what happened, do the conservative thing and reset all
         % stored velocity values.  Position is shifted 90% of the way towards the new value
         dxc = 0;
         dyc = 0;
         last_dxc = 0;
         last_dyc = 0;
         last_xc = .9*wcx+ .1*last_xc; 
         last_yc = .9*wcy+ .1*last_yc; 
       
         % recombine all points together for finding fit without shifting pixels forward and backward
         fit_pixels = [last_pixels; cur_pixels; next_pixels];

         % exclude points that are outside of our new local neighborhood defined by inclusion_rad
         % using the center defined by the local weighted mean
		   [n m] = size(fit_pixels);
         dist = sqrt(sum(((fit_pixels - [last_xc*ones(n,1) last_yc*ones(n,1)]).^2)'))';
         keep_points_i = dist<inclusion_rad;
         num_excl = sum(~keep_points_i);
         num_incl = sum(keep_points_i);

         lost_ts = [lost_ts; cur_ts];
      end;  % if num_excl>num_incl
      
      % OK, now we actually trim our pixel values to be within the inclusion radius
      fit_pixels = fit_pixels(keep_points_i,:);
      
      % here we log all the ts where the rat's position was completely lost
      %if isempty(fit_pixels)
      %   last_pixels = [];
      %   lost_ts = [lost_ts; cur_ts];
      %  continue;
      %end
      
      % make the set of pixels sent to the fitting algorithm be unique
		fit_pixels = unique(fit_pixels, 'rows');
		
		[xc yc dpjump] = fit_circle(fit_pixels(:,1), fit_pixels(:,2), last_xc+dxc, last_yc+dyc, headstage_rad);
		if isinf(xc)
         break;
      end;
      
      if dpjump>.1   % this indicates that the fitting algorithm failed miserably.  
                     % Results can be radically wrong so don't trust them
                     % in that case, we just estimate location from the previous location an estimated velocity
            cur_xc = last_xc+dxc;
            cur_yc = last_yc+dyc;
      else
         cur_xc = (1-hist_fac)*xc + hist_fac*(last_xc+dxc);
         cur_yc = (1-hist_fac)*yc + hist_fac*(last_yc+dyc);
      end;
      
      pos_data(pos_data_counter, :) = [cur_ts cur_xc cur_yc 0 0];
      pos_data_counter = pos_data_counter+1;
      
		if check_flag>=1
         draw_circle([xc yc], headstage_rad, 360, 'r');
		   hold on;
         draw_circle([cur_xc cur_yc], headstage_rad, 360, 'b');
		
		   if ~isempty(cur_pixels)
            plot(cur_pixels(:,1), cur_pixels(:,2), '.k');
         end
         if ~isempty(next_pixels_shifted)
            plot(next_pixels_shifted(:,1), next_pixels_shifted(:,2), '.g');
         end
         if ~isempty(last_pixels_shifted)
			   plot(last_pixels_shifted(:,1), last_pixels_shifted(:,2), '.b');
		   end;
		   axis equal;
         axis([0 frame_width 0 frame_height]);
		   hold off;
		   text(5,15,num2str(cur_ts), 'color', [0 0 0]);
		   if j == 1; figure(gcf); end;
		   drawnow;
      end

      %xc = cur_xc;
      %yc = cur_yc;
      
      % figure out rate of change of x and y position
      % this is used for predictive purposes (used above)
      cur_dxc = cur_xc - last_xc;
      cur_dyc = cur_yc - last_yc;
      dxc = .95*(vel_momentum*dxc + (1-vel_momentum)*cur_dxc);  % allow velocity to change only slowly and keep decaying towards zero
      dyc = .95*(vel_momentum*dyc + (1-vel_momentum)*cur_dyc);   % allow velocity to change only slowly and keep decaying towards zero

      last_xc = cur_xc;
		last_yc = cur_yc;
		
		last_pixels = cur_pixels;
               
	end  % j

    
end  % while not end-of-file

pos_data = pos_data(1:pos_data_counter-1,:);  % clip off rows of zeros at the end that occur
                                             % because we had to allocate the variable without knowing
                                             % how long it was

% INTERPOLATE
disp('INTERPOLATING POSITION DATA...');
pos_data = interp_pvd(pos_data);

% SMOOTH
if smooth_flag
   disp('SMOOTHING POSITION DATA...');
   pos_data = smooth_pvd(pos_data);
end;
                                             
if ~check_flag
   fprintf(fid_out, '%.0f\t%.0f\t%.0f\t%.0f\t%.0f\r\n', pos_data');
   fclose(fid_out);
end

fclose(fid_in);

if ~isempty(lost_ts)
   disp('WARNING: LOST RAT AT THE FOLLOWING TIMESTAMPS')
   disp(num2str(lost_ts, 11));
end;


return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION INTERP_PVD
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [interp_pvd] = interp_pvd(pos_data)
% INTERP_PVD  fill in position data for missing timestamps in video data
% first scans for missing timestamps then fills in missing
% x and y position using linerar interpolation
% pos_data has the format [ts posx posy vel dir]
% vel and dir are not currently interpolated, just zeros are returned

ts = pos_data(:,1);
x = pos_data(:,2);
y = pos_data(:,3);

ts_new = [];
x_new = [];
y_new = [];

% determine the standard timestamp increment
% first create a histogram to find the most frequent
% incriment, then select this bin and average the values
hist_edges = [0:1000:200000];
diff_subset = diff(ts(1:min(1000,length(ts))));
counts = histc(diff_subset, hist_edges);
[mxcnt max_i] = max(counts);
max_i;
hist_edges;
good_vals = diff_subset(diff_subset>=hist_edges(max_i) & diff_subset<hist_edges(max_i+1));
ts_incr = mean(good_vals);

ts_diff = diff(ts);

gaps = find(ts_diff>ts_incr*1.9);
last_end_i = 1;

disp('GAPS FOUND AT: ')
disp(num2str(ts(gaps),11));
disp(['Total: ' num2str(length(gaps)) ' gaps in ' num2str(length(ts)) ' timestamps.']);

for i = 1:length(gaps)
   start_i = gaps(i);
   end_i = gaps(i)+1;
   
   start_ts = ts(start_i);
   end_ts = ts(end_i);
   
   % add all ts, x and y since last gap ended
   ts_new = [ts_new; ts(last_end_i:start_i)];
   x_new = [x_new; x(last_end_i:start_i)];
   y_new = [y_new; y(last_end_i:start_i)];
   
   % find the ts's to be inserted
   ts_temp = [start_ts:ts_incr:(end_ts - .5*ts_incr)]';
   ts_insert = ts_temp(2:end);
   
   % find the 10 timestamps, x and y values
   % preceding the present gap
   % we actually need to look these up in the ts_new
   % list just in case there was a gap in the preceding
   % 10 timestamps
   pre_index= max(1,length(ts_new)-10):length(ts_new);
   ts_pre = ts_new(pre_index);
   x_pre = x_new(pre_index);
   y_pre = y_new(pre_index);
   
   % find 10 timestamps, x and y values
   % following the end of the current interval
   % this is complicated by the possibility that another gap 
   % occurred in the next 10 ts.  In that case, we need to stop before
   % the gap.
   if i+1<=length(gaps)
      %gaps(i+1)
      post_index = end_i:min([length(ts) end_i+10 gaps(i+1)]);
   else
      post_index = end_i:min([length(ts) end_i+10]);
   end;
   ts_post = ts(post_index);
   x_post = x(post_index);
   y_post = y(post_index);
   
   % now do the actual interpolation
   x_insert = interp1([ts_pre; ts_post], [x_pre; x_post], ts_insert, 'linear');
   y_insert = interp1([ts_pre; ts_post], [y_pre; y_post], ts_insert, 'linear');
   
   % add ts, x and y for present gap
   ts_new = [ts_new; ts_insert];
   x_new = [x_new; x_insert];
   y_new = [y_new; y_insert];
   
   last_end_i = end_i;
   
   if 0  % diagnostics
      subplot(2,1,1)
       plot([ts_pre; ts_post], [x_pre; x_post]);
       hold on;
       plot(ts_insert, x_insert, 'r');
       hold off;
       subplot(2,1,2)
       plot([ts_pre; ts_post], [y_pre; y_post]);
       hold on;
       plot(ts_insert, y_insert, 'r');
       hold off;
       
       pause;
    end   
    
end;

% add the remaining data after the last gap
ts_new = [ts_new; ts(last_end_i:end)];
x_new = [x_new; x(last_end_i:end)];
y_new = [y_new; y(last_end_i:end)];


interp_pvd = [ts_new x_new y_new 0*ts_new 0*ts_new];  % note the zeros for velocity and direction

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION SMOOTH_PVD
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [smooth_pvd] = smooth_pvd(pos_data);

% smooth position data by using running average.  
% pos_data has the format [ts posx posy vel dir]
% vel and dir are not currently interpolated, just zeros are returned

ts = pos_data(:,1);
x = pos_data(:,2);
y = pos_data(:,3);

x_new = [];
y_new = [];

% WINDOW samples both pre and post will be considered
% for each samples being smoothed.

WINDOW = 6;
%b = ones(1,WINDOW)/(WINDOW);  % this is a simple running average
gauss_i = -WINDOW/2:WINDOW/2;
b = gaussian(gauss_i, 0, WINDOW/4)/sum(gaussian(gauss_i, 0, WINDOW/4));

% Now, use samples from the past and future to smooth the present (acausal filtering).
% Filtering uses Matlab's "filtfilt" routine which sets the order of filtering
% by the 'b' coefficient, which roughly states how many samples are used in each fit.
% "filtfilt" returns all NaN's if any data point is a NaN.  This will cause problems
% at the start of the file where VT.interp contains a few startup NaN's.

x_new = filtfilt( b, 1, x );           % x position
y_new = filtfilt( b, 1, y );           % y position
%vv = filtfilt( b, 1, V(:) );                % velocity
%dd = filtfilt( b, 1, exp( cmplx * D(:) ) ); % head direction
%dd = atan2( imag(dd), real(dd) );

smooth_pvd = [ts x_new y_new 0*ts 0*ts];  % note the zeros for velocity and direction

return;
