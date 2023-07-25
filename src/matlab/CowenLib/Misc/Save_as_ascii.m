function fid = Save_as_ascii(M, fname, is_integer)
%function fid = Save_as_ascii(M, fname)
%
% Save a file as ascii witout the scientific notation present in the
% builtin save function.
%
% INPUT:
%        M = matrix or vector to save
%    fname = a file name
%    is_integer = optional flag to save as int instead as floating point.
%
% OUTPUT: 
%      fid = -1 if unable to open file, fid otherwise.
%
% cowen Fri Jul  2 13:13:10 1999
if nargin == 2
  is_integer = 0;
end

[r,c] = size(M);
fid = fopen(fname,'w');
if fid == -1
  return
end

if is_integer
  for ii = 1:r
    fprintf(fid,'%d\t',M(ii,:));
    fprintf(fid,'\n');
  end
else
  for ii = 1:r
    fprintf(fid,'%f\t',M(ii,:));
    fprintf(fid,'\n');
  end
end
fclose(fid)