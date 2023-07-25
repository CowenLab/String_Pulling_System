function [S_ctsa,T] = Load_spikes(tfile_list)
%
% Purpose: Load in a ctsa object of spike times.
%
% Input: 
%        A filename that contains a list of all the tfiles
%
% Output:
%        A ctsa of spike times.
%        A vector of lenght equal to the number of cells, listing the 
%          tetrode each cell belongs to. (Assumes tfiles are in TET_* directories)


F = ReadFileList(tfile_list);
T = Assign_tet_numbers(F);
S_ctsa = LoadSpikes(F);
