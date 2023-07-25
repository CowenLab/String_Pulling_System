% * binning by interval
% * MEX file
% * input: 1: Spike or other timestamped data -- n_spikes x 1, assumed to
% be sorted NOT A CELL ARRAY!!
% * input: 2: n_intervals x 2 matrix of intervals. The spike times will be binned into 
% *			 these intervals. Also assumed to be sorted. The spikes are counted from 
%   input  3: Passing a 1 as param 3 forces it to just bin by interval, otherwise
% it attempts to choose intelligently whether to bin by interval or by
% timestamp. This is just a test so that you can double check to make
% sure binning in the two versions is proceeding identically.
% the values in col 1 up to but NOT including the values in col 2.
% * output: A vector of length n_intervals that contains the spike counts to each element in the bin.
% 
%   * NOTE: ASSUMES TIMESTAMPS ARE SORTED AND THE INTERVALS ARE SORTED BY THE FIRST COLUMN.
% [Q]= bin_times_by_intervals(SD.T{1}*100,[TrTy.CS1StartTimesUsec{1}(:) TrTy.CS1EndTimesUsec{1}(:)])