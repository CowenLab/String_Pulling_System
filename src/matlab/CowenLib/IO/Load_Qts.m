function S = Load_Qts(data_set, dt)
%function S = Create_Qtsa(data_set, dt)
%
% Purpose: Create a spike object
%
% Input: 
%        A dataset in the form of a list of tfiles and a dt(in ms) interval.
%
% Output:
%        A ts in which each 'cell' is a neuron.


% Load in the data sets.

F = ReadFileList(data_set);
S = LoadSpikes(F);
