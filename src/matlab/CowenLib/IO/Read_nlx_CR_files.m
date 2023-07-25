%  Read_nlx_CR_files (file_names_cell_array, sFreq, intervals_in_timestamps) 
%  Read a set of CR files at once at the specified sampling frequency and send it off to matlab.
%  MEX file
% 
% 
%  input:
%     cell array of file names
%     sFreq = the sampling frequency of the outputted data. Leaving empty will assume the file's standard samplnig rate.
%     intervals - a n X 2 matrix of start and end timestamps or records (not implemented yet).
%    
%  
%  output:
%     [t,D]
%     t = timestamps for EACH record
%     D = Data: the data you wish to read where each column corresponds to each file you passed in.
% TODO
%     interval_indices = would be nice if this returned the start and end index of each interval so that you 
%            could then could quickly pull the intervals out of the data.
%  
%  NOTE: THIS DOES NOT WORK IF YOU DESIRE A SAMPLING RATE HIGHER THAN THE ORIGINAL RATE.
% 
%  [a, b] = Read_nlx_CR_files({'CSC11.ncs' 'CSC10.ncs'},100,[1215413846 1415413846;1515413846 1815413846 ]); 
% 
%  version 0.7 Stephen L. Cowen
%  cowen(2004)  cowen feb 06 got rid of the inlines which screwed things up for the default compiler 
%    (requires a cpp compiler and the builtin matlab compiler is not cpp)
