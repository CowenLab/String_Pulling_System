% function M = load_text_matrix(fname, vararg)
% Load a text matrix. The main purpose of this routine is to load in data from files as
% they are being written. This requires that partially written lines are ignored. To
% my knowledge, you can't do this in matlab -- other than by reading line by line 
% in a loop which is painfully slow. Thus this program
% MEX file.
% INPUT:
%
% input: 1: the file name
% input: 2 (optional): If positive, the number of lines from the head of the file to read in (number of rows in the matrix)
%          If negative, the number of lines from the end of the file. 
% input: 3 (optional) If 3 inputs are passed, the 2nd is considered to be the start row and the third is the end row.
% 
%  OUTPUT:
%   the matrix, formed from the text file for the region specified.
%
%
%  PROBLEMS: 1) any trailing spaces on the first row will screw things up.
%             2) Does not dynamically allocate memory for file positions so it will bomb for large files.
% cowen 2002            
