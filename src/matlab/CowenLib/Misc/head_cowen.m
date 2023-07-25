function your_text = head_cowen(fname,numLines)
% read out the first n lines of some HUGE or whatever text file.
% cowen 2017
if nargin < 2
    numLines = 20;
end
 fid = fopen(fname,'r');
 your_text = cell(numLines,1);
 for ii = 1:numLines
     your_text(ii) = {fgetl(fid)}; 
 end
 fclose(fid);