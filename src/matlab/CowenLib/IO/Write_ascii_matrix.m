function f = Write_ascii_matrix(M, filename, type, openmethod)
%function f = Write_ascii_matrix(M, filename)
% Write an ascii matrix in floating point decimal notation
% (the save option puts everything in scientific notation.)
%
% type is optional(float is the default). You can also pass 'int' to
% print out in integer.
if nargin < 3
    type = 'float';
end
if nargin < 4
   openmethod = 'w';
end


fp = fopen(filename, 'w');
[ r, c] = size(M);

for ii = 1:r
  switch type
    case 'float'
      fprintf(fp,'%f ',M(ii,:));
    case 'int'  
      fprintf(fp,'%i ',M(ii,:));
    otherwise
      error('incorrect type');
  end
  fprintf(fp,'\n');
end
fclose(fp);
f = ii;