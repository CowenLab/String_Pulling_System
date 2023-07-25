function [O,N] = Assign_tet_numbers(dset,is_hyper4)
% Assign tetrode numbers to each cell in the ctsa.
% Since this is not stored with the data, be sure to keep this aligned
% with the ctsa. ASSUMES directories in form /TET_4
% 
% INPUT: a cell array of the t files.
%
% OUTPUT: a vector of the lenght of the cell array(number of neurons) 
%         that has a unique number for each tetrode
%

% cowen Mon May 24 09:18:50 1999
if nargin == 1
  is_hyper4 = 0;
end

O = zeros(length(dset),1);
N = zeros(length(dset),1);
for ii = 1:length(dset)
  jj = 1;
  % Get the tetrode number
  while(jj <= 9999 & jj <= length(dset{ii})-6)
    if strcmp(upper(dset{ii}(jj:jj+3)), 'TET_')
      num1 = dset{ii}(jj+4);
      num2 = dset{ii}(jj+5);
      jj = 9999;
      if num2 == '/' | num2 == '\'
        O(ii) = str2num(num1);
      else
        O(ii) = str2num(num1)*10 + str2num(num2);
      end
    end
    jj = jj + 1;
  end
  % Get the cell number
  n1 = dset{ii}(end-3:end-3);
  n2 = dset{ii}(end-2:end-2);

  if is_hyper4
    da_string = '_';
  else
    da_string = '.';
  end
  if n1 == da_string
    N(ii) = str2num(n2);
  else
    N(ii) = str2num(n1)*10 + str2num(n2);
  end
end
