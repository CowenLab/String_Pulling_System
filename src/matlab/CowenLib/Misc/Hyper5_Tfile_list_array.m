function tfl = Hyper5_Tfile_list_array(data_dir,use_un_sorted)
% Create a cell array of the target tfiles
%
% INPUT: the data directory
%   optional use_un_sorted : use un sorted data(So you get internuerons and wierd clusters.
%
% OUTPUT: Cell array of .tfl names.

% cowen Mon Mar 29 17:57:41 1999

% Check to see if it's the old data. If so, there is a different file name.
if nargin == 1
  use_un_sorted = 0;
end

if (strcmp(data_dir(21:end),'Mark_ctx_data'))
  tfl{1} = fullfile(data_dir,'all.tfl'); %
else
  if fopen(fullfile(data_dir,'tfiles' ,'sleep1.tfl')) > 0 & ~use_un_sorted
    tfl{1} = fullfile(data_dir,'tfiles' ,'sleep1.tfl'); %
    tfl{2} = fullfile(data_dir,'tfiles', 'maze1.tfl');  %
    tfl{3} = fullfile(data_dir,'tfiles', 'sleep2.tfl'); %
    tfl{4} = fullfile(data_dir,'tfiles', 'maze2.tfl');  %
    tfl{5} = fullfile(data_dir,'tfiles', 'sleep3.tfl'); %
  else 
    error('Will not use unsorted cells.')
%    tfl{1} = fullfile(data_dir,'Raw_tfiles' ,'sleep1.tfl'); %
%    tfl{2} = fullfile(data_dir,'Raw_tfiles', 'maze1.tfl');  %
%    tfl{3} = fullfile(data_dir,'Raw_tfiles', 'sleep2.tfl'); %
%    tfl{4} = fullfile(data_dir,'Raw_tfiles', 'maze2.tfl');  %
%    tfl{5} = fullfile(data_dir,'Raw_tfiles', 'sleep3.tfl'); %
  end
end