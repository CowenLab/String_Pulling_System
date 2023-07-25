function data_dir = Data_set_cell_array()
% Create a cell array of the targe data sets
%
% INPUT: nothing
%
% OUTPUT: Cell array of data sets.

% cowen Mon Mar 29 17:57:41 1999

% The essential data directories.

% New
Datadir1 = fullfile(filesep,'home','Data','2','hyper5', filesep);
% Old
Datadir2 = fullfile(filesep,'home','Data','2','hyper5','Poster_98_data',filesep);
% Other
Datadir3 = fullfile(filesep,'home','Data','2','cowen',filesep);

% New data.
data_dir{1}  = fullfile(Datadir1,'6429','6429_01');
data_dir{2}  = fullfile(Datadir1,'6429','6429_04');
data_dir{3}  = fullfile(Datadir1,'6429','6429_07');
data_dir{4}  = fullfile(Datadir1,'6436','6436_02');
data_dir{5}  = fullfile(Datadir1,'6436','6436_05');
data_dir{6}  = fullfile(Datadir1,'6436','6436_08');
data_dir{7}  = fullfile(Datadir1,'6481','6481_01');
data_dir{8}  = fullfile(Datadir1,'6481','6481_04');
data_dir{9}  = fullfile(Datadir1,'6481','6481_07');
data_dir{10} = fullfile(Datadir1,'6568','6568_01');
data_dir{11} = fullfile(Datadir1,'6568','6568_04');
data_dir{12} = fullfile(Datadir1,'6568','6568_07');

% Old Data from Hemant. Used for Poster 98
data_dir{21} = fullfile(Datadir2, '5672_07');% 
data_dir{22} = fullfile(Datadir2, '5672_08');% 
data_dir{23} = fullfile(Datadir2, '5672_09');% 
data_dir{24} = fullfile(Datadir2, '6207_01');% 
data_dir{25} = fullfile(Datadir2, '6207_02'); 
data_dir{26} = fullfile(Datadir2, '6207_03'); 
data_dir{27} = fullfile(Datadir2, '6207_14'); 
data_dir{28} = fullfile(Datadir2, '6207_15'); 
data_dir{29} = fullfile(Datadir2, '5631_08'); 
data_dir{30} = fullfile(Datadir2, '5631_10'); 
data_dir{31} = fullfile(Datadir2, '5358_05'); 
% Other
%data_dir{31} = fullfile(Datadir3,'cowen', 'Tmp'); % Temporary dataset for testing autocut.
