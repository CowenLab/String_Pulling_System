function process_videowm(vid_dir, epoch_times, check_flag);
% PROCESS_VIDEOWM altered version of process_video_labversion, tracks using weighted mean
%                   tracks based on raw red, raw green and luminance
%                   I've removed support for multiple maze sessions, as well.
%                   As with other version of video tracking, there is an exlusion 
%                   radius.  Pixels outside this radius don't contribute to the fix
%                   unless they start to outnumber the pixels inside the circle.  See
%                   extractvidposwm for more details.
% process_video  generate pvd (position-velocity-direction) file from video file
%     process_video(vid_dir, proc_epochs, check_flag);
%  Inputs:
%     proc_epochs is an array containing start and stop times for all epochs to be processed
%         its format is:
%              [start1 stop1
%               start2 stop2]
%         note that each row is a separate epoch and second row is optional
%         a separate video file will be created for each epoch
%         times are in microseconds (not cheetah timestamp units)
%     vid_dir = directory where video file is located 
%               (note that the entire path must be free of spaces.  i.e., 
%                 c:\data\video_data\7808-25 is ok,
%                 c:\data\video data\7808 24 is not)
%     check_flag = set to 1 to watch video extraction, set to 0 for unsupervised extraction
%
%  needed files: VT1.zip (or VT1.dat or VT1.nvt)
%
%  If VT file is not unzipped, it will be unzipped.  The VT file is converted 
%  into two ascii files, one for each maze session using timestamps from the events file.
%  These ascii files are deleted at the end of processing if they were created by this program.
%
%  check_flag can be 0 (no checking), 1, 2, or 3 as detailed below.
%  In check mode, the program will show ongoing fit of circle to the data.  It is best to run 
%  program in check mode for a while to insure it is processing data correctly, then Cntl-C and 
%  rerun the program with check off.  (Note that if you break program in check mode, the intermediate ascii files may or may 
%  not be erased after processing the next time.)
%  During check mode, the video frames and best-fitting circle will be shown throughout extraction.  The program will also stop
%  at the beginning to show you the first attempt at finding the rats location.
%  Depending on the value of check_flag, it may also stop whenever there are pixels outside the inclusion radius.
%  You will need to hit any key to continue extraction in all cases.
%  CHECK_FLAG DETAILS:
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
%  see extractvidpos.m for details of extraction and for more about extraction parameters (hard-coded here)
%  Dependencies:
%      cutvideo.exe  -  translates VT.dat to ascii within specified window
%      unzip.exe     -  command line unzip utility from info-zip
%      extractvidposwm.m - extracts video position via fitting points to a circle
%      find_lwc - used by extractvidposwm to find the local weighted center
%      gaussian.m    - used during smoothing
%
% output is a .PVD file which is an ascii file with the following columns:
% [Timestamp Xpos Ypos Velocity Direction]
% Velocity and Direction columns are presently just zeros, as this info has not been extracted.

%  David Euston, 9/27/2004

if nargin<3
   check_flag = 0;
end;

%headstage_rad = 9;  % these are in pixel units
error_track_threash = 6;  % algorithm counts number of times exluded points exclude included
                          % this threashold determines when corrective action should be taken (see extractvidposwm)
inclusion_rad = 28;   % pixel units

[path name ext] = fileparts(vid_dir);
datestring = datestr(now);
datestring(datestring==' ') = '_';
datestring(datestring==':') = '-';
log_file = ['vid_proc_' name '_' datestring '.log'];
if ~check_flag
   diary([vid_dir '\' log_file]);
end

unzip_flag = 0;  % set to 1 if VT.zip file unzipped, at end we delete zip file
maze1ascii_flag = 0;  % set to 1 if vtm1.ascii file created, file is deleted at end
maze2ascii_flag = 0;  % set to 1 if vtm2.ascii file created, file is deleted at end
maze2_flag = 0; % set to 1 if a second epoch is present

maze1_starttime = epoch_times(1,1);
maze1_endtime = epoch_times(1,2);
disp(['Epoch 1 start time: ' num2str(maze1_starttime,11)]);
disp(['Epoch 1 end   time: ' num2str(maze1_endtime,11)]);
if size(epoch_times, 1)>1
      maze2_starttime = epoch_times(2,1);
      maze2_endtime = epoch_times(2,2);
      disp(['Epoch 2 start time: ' num2str(maze2_starttime,11)]);
      disp(['Epoch 2 end   time: ' num2str(maze2_endtime,11)]);
      maze2_flag = 1;
end;

vid_in = [vid_dir '\vt1.dat'];
if ~exist(vid_in, 'file') & exist([vid_dir '\vt1.nvt'], 'file')
   vid_in = [vid_dir '\vt1.nvt'];
end;
vid_zip_in = [vid_dir '\vt1.zip'];
ascii_out1 = [vid_dir '\vtm1.ascii'];
ascii_out2 = [vid_dir '\vtm2.ascii'];

need_VT = 0;
if ~exist(ascii_out1, 'file')
   need_VT = 1;
end;
if maze2_flag & ~exist(ascii_out2, 'file')
   need_VT = 1;
end;

% look for VT.dat or VT.zip and unzip file if needed

if need_VT & ~exist(vid_in, 'file')
   if exist(vid_zip_in, 'file')
		disp('Unzipping VT.zip file');
		eval(['!unzip ' vid_dir '\VT1.zip -d ' vid_dir]);
		unzip_flag = 1;  % this will let us know to erase the file at the end
		if ~exist(vid_in, 'file') & exist([vid_dir '\vt1.nvt'], 'file')
		   vid_in = [vid_dir '\vt1.nvt'];
		end;
   else
		error(['Unable to find video file: ' vid_in]);
		diary off;
   end
end;

if exist(ascii_out1, 'file')
   disp(['ASCII Video file exists, using: ' ascii_out1]);
else
	disp('Translating VT file to ASCII');
   maze1ascii_flag = 1;  % this lets us know to erase the ascii file at the end of processing
	cmd = ['!cutvideo -inp ' vid_in ' -outp ' ascii_out1 ' -start ' num2str(maze1_starttime,11) ' -end ' num2str(maze1_endtime, 11)];
	disp(cmd)
	eval(cmd);

end;   

if unzip_flag
   delete(vid_in)
end

infile = ascii_out1
outfile = [vid_dir '\vtm1.pvd']
extractvidposwm(infile,  outfile, error_track_threash, inclusion_rad, check_flag, 1);

if maze1ascii_flag
   delete(ascii_out1)
end

diary off;

return;