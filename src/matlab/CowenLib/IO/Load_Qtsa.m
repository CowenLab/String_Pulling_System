function Q_ctsd = Load_Qtsa(data_set, dt)
%function Q_tsarray = Create_Qtsa(data_set, dt)
%
% Purpose: Create a sparse Q matrix ctsd object
%
% Input: 
%        A dataset in the form of a list of tfiles and a dt(in ms) interval.
%
% Output:
%        A ctsd in which the main structure is a |t| x nCells histogram of firing rates,


% Load in the data sets.

F = ReadFileList(data_set);
S = LoadSpikes(F);
Q_ctsd = MakeQfromS(S, dt*10); % The # 10 is to convert to timestamp dt.
