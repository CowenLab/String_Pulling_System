function [seqevents, epoch_times] = read_events(infile); 
% READ_EVENTS  reads Events.dat.txt file from cheetah (via dat2txt.exe conversion)
%              interprets port values in terms of sequence experiment
%              events.
% 			seqevents = read_events(infile);
% infile can be omitted and program will look for events.dat.txt in current directory
% seqevents is an array with the following columns:
% seqevents = [timestamp tone stim zone]
% timestamps are in microseconds (standard cheetah format)
% tone and stim are binary, 1 = on, 0 = off
% zone numbers range from 0 to 7, -1 means no zone specified
% 
% epoch_times is an array of the start and stop times of each behavioral epoch
% they are in microseconds (same as cheetah timestamps)
% these epochs are denoted by "a" and "b" events inserted into the events.dat file
% during recording session.  
% epoch_times = 
% [start1 stop1]
% [start2 stop2]
% ...


if nargin<1
	infile = 'events.dat.txt';
end;

fid = fopen(infile);
if fid==-1
	error(['Could not open file: ' infile]);
end;
	
i = 1;
epoch_row = 0;
last_flag = '';
timestamp = [];
tone = [];
stim = [];
zone = [];

while ~feof(fid)
	curline = fgetl(fid);
   
   % deal with header and blank lines
	if isempty(curline) | length(curline)<5 | all(curline(1:4)=='none')
		continue; 
	end; 
	[ts] = sscanf(curline, '%*i,%*i,%*i,%lf'); 
	[eventstr] = sscanf(curline, ...
		'%*i,%*i,%*i,%*lf,%*i,%*i,%*i,%*i,%*i,%*i,%*i,%*i,%*i,%*i,%*i,%*i,%*i,%40c');
	ttltxti = findstr(eventstr, 'TTL Value:');
	if ~isempty(ttltxti) & length(eventstr)>=40
		ttlvalstr = eventstr(ttltxti+15:length(eventstr));  % note: values look like:
																			 % FFFFE080, we strip off
																			 % the four leading Fs
		ttlvalbin = dec2bin(hex2dec(ttlvalstr),16);  % (e.g., 1100000000100000)
		%disp(ttlvalbin);
		valbinflip = fliplr(ttlvalbin);              % reverse the binary number
																	% so that string indices correspond
																	% to bit locations
		tone(i) = str2num(valbinflip(14));        % bit 14 carries tone onset info
		stim(i) = ~(str2num(valbinflip(15)));     % bit 15 went low when stim delivered
		lighti = find(valbinflip(1:8)=='1');      % first 8 bits tell which light
		if ~isempty(lighti)
			zone(i) = lighti-1;
		else
			zone(i) = -1;
		end;
 	else
		tone(i) = 0;
		stim(i) = 0;
		zone(i) = -1;
	end;
	timestamp(i) = ts;
	%disp(curline)
	i = i+1;
   
   % Process the User entered event codes which denote epochs
   if length(eventstr)<=2
      cur_event_flag = sscanf(eventstr, '%s');  % remove white space
      switch cur_event_flag 
			case 'a'
             if ~isempty(last_flag) & (last_flag == 'a')
                disp(['Warning: Missing "b" event flag before "a" at timestamp ' num2str(ts)])
             end;
             epoch_row = epoch_row + 1;
             epoch_times(epoch_row, 1) = ts;
             last_flag = 'a';
			case 'b'
             if last_flag ~= 'a' 
                disp(['Warning: "b" event flag without "a" at timestamp ' num2str(ts)])
                epoch_row = epoch_row + 1;
             end;
             epoch_times(epoch_row, 2) = ts;
             last_flag = 'b';
			otherwise
             disp(['Warning: Unknown User Input Event, "' eventstr '" , at timestamp ' num2str(ts)]) 
      end;
   end;

end;

fclose(fid);

seqevents = [timestamp' tone' stim' zone'];

% remove any 'all clear' events (sent to output port to turn off lights)
keepi = ~(tone==0 & stim==0 & zone==-1);
seqevents = seqevents(keepi,:);
