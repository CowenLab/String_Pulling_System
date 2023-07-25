
if filter_on_density

  % Filter out population vectors that are below that threshold
  %s1j = find( ds1 < density_threshold_s1);
  %s1_cut = length(s1j);
  %Q_s1.data(:,s1j) = [];

  m1j = find( dm1 < density_threshold_m1);
  m1_cut = length(m1j);
  Q_m1.data(:,m1j) = [];
  Q_m1.times(:,m1j) = [];

  %s2j = find( ds2 < density_threshold_s2);
  %s2_cut = length(s2j);
  %Q_s2.data(:,s2j) = [];
  %Q_s2.times(:,s2j) = [];
end

disp(['Cut out ' num2str(original_cells - Rows(Q_s1.data)) ' cells.']);
disp(['Cut out state vectors: S1:' num2str(s1_cut) ' M1:' ...
      num2str(m1_cut) ' S2:'  num2str(s2_cut) ]); 




% Make sure the parameters are within range, if not, make them within range.
if(SLEEP1_BINS == 0 | SLEEP1_BINS > Cols(Q_s1.data)-1)
  SLEEP1_BINS = Cols(Q_s1.data) - 1 ;
end
if(SLEEP2_BINS == 0 | SLEEP2_BINS > Cols(Q_s2.data)-1)
  SLEEP2_BINS = Cols(Q_s2.data) - 1 ;
end

% Maze: By default, grab the middle time window.
if (MAZE_BINS == 0 | MAZE_BINS > Cols(Q_m1.data)-1)
  MAZE_BINS = Cols(Q_m1.data) - 1 ;
  maze_start = 1;
  maze_end = Cols(Q_m1.data);
else % Grab the middle.
  maze_start = floor(Cols(Q_m1.data)/2 - MAZE_BINS/2) + 1;
  maze_end = maze_start +  MAZE_BINS; 
end




disp('sleep1 maze sleep2');
[ SLEEP1_BINS MAZE_BINS SLEEP2_BINS  ]

  % You want the end of S1, the beginning of S2 and the middle of Maze.

Q_s1.data = Q_s1.data(:,end-SLEEP1_BINS:end); % From end of period back
Q_s2.data = Q_s2.data(:,1:SLEEP2_BINS); % From start to end.
Q_m1.data = Q_m1.data(:,maze_start:maze_end); % Middle of period.
Q_s1.times = Q_s1.times(:,end-SLEEP1_BINS:end); % From end of period back
Q_s2.times = Q_s2.times(:,1:SLEEP2_BINS); % From start to end.
Q_m1.times = Q_m1.times(:,maze_start:maze_end); % Middle of period.

disp(['Average frequencies: S1 ' num2str(Avg(Frequencies(Q_s1.data, DT))) ' Maze ' num2str(Avg(Frequencies(Q_m1.data, DT))) ' S2 ' num2str(Avg(Frequencies(Q_s2.data, DT))) ]);

