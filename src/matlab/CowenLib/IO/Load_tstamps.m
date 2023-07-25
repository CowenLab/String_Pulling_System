function [s1,m1,s2] = Load_tstamps(data_dir, RIPPLES)
%function O = Load_tstamps(data_dir, RIPPLES)
%
% INPUT: the data directory of the timestamp files and a code telling
% what timestamps to load.
%
% OUTPUT: The timestamp matrix([start end;start end;....]
%


s = filesep;

if RIPPLES == 1 % Ripples
  load( [data_dir s 'eeg' s 'riptimes_s1_timestamps']);
  load( [data_dir s 'eeg' s 'riptimes_s2_timestamps']);
  load( [data_dir s 'eeg' s 'interriptimes_m1_timestamps']);

  s1 = riptimes_s1_timestamps;
  s2 = riptimes_s2_timestamps; 
  m1 = interriptimes_m1_timestamps;
  
  clear riptimes_s1_timestamps riptimes_s2_timestamps interriptimes_m1_timestamps
elseif RIPPLES == -1 % Interripples
  load( [data_dir s 'eeg' s 'interriptimes_s1_timestamps.equated']);
  load( [data_dir s 'eeg' s 'interriptimes_s2_timestamps.equated']);
  load( [data_dir s 'eeg' s 'interriptimes_m1_timestamps']);
1
  s1 = interriptimes_s1_timestamps;
2
  s2 = interriptimes_s2_timestamps; 
3
  m1 = interriptimes_m1_timestamps;
  
  clear  interriptimes_s1_timestamps interriptimes_s2_timestamps interriptimes_m1_timestamps
elseif RIPPLES == 0
  % Do not sort by ripples or interripples. Just get the raw data.
  load( [data_dir s 'eeg' s 'interriptimes_s1_timestamps.equated']);
  1
  load( [data_dir s 'eeg' s 'interriptimes_s2_timestamps.equated']);
  2
  load([data_dir s 'eeg' s 'interriptimes_m1_timestamps']) ;
  3
  % Find the start and end of the data, ignore everything else. 
  s1 = [interriptimes_s1_timestamps(1,1)  interriptimes_s1_timestamps(end,2) ]
  % Just look at the periods the rat is running around and not spaced
  % out in LIA 
  %  m1_timestamps = interriptimes_m1_timestamps;
  m1 = [interriptimes_m1_timestamps(1,1)  interriptimes_m1_timestamps(end,2) ]
  s2 = [interriptimes_s2_timestamps(1,1)  interriptimes_s2_timestamps(end,2) ]
  clear  interriptimes_s1_timestamps interriptimes_s2_timestamps interriptimes_m1_timestamps
end

% Filter out any screwed up timestamps. 
s1 = Fix_timestamps(s1);
m1 = Fix_timestamps(m1);
s2 = Fix_timestamps(s2);


