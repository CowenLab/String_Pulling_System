function ca_of_ts_objects = Load_ts_objects(dir_or_file_path,what_to_load)
%function ca_of_ts_objects = Load_ts_objects(dir_or_file_path,what_to_load)
% INPUT 
%  directory or file of the ts object mat file
%  what to load-- a string that specifies things like no_interneuron or no_pyramidal
%
% OUTPUT:
%  a cell array of ts objects.
%
% cowen
if nargin < 2
    what_to_load = [];
end
if ~iscell(what_to_load)
    what_to_load = {what_to_load};
end
if isempty(what_to_load{1})
    what_to_load = [];
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load the files. If a wildcard is specified, then load all files with
% that name.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all_files = find_files(dir_or_file_path);
% if exist(dir_or_file_path,'dir')
%     the_path = dir_or_file_path;
%     files = dir(fullfile(dir_or_file_path,'ts*.mat'));
%     for ii =1:length(files)
%         all_files{ii} = fullfile(the_path,files(ii).name);
%     end
% else
%     if isempty(findstr(dir_or_file_path,'*'))
%         [the_path, the_name, the_ext] = fileparts(dir_or_file_path);
%         all_files{1} = fullfile(the_path,the_name,the_ext);
%     else
%     end
% end   
count = 1;
for ii = 1:length(all_files)
    a_ts = load(ts,all_files{ii}); 
    [cd,type] = get(a_ts,'cell_type');
    type = upper(type);
    if isempty(type)
        disp('WARNING: This object does not contain the cell type information so cannot filter.')
    end
 
    load_it = 1;
    for jj = 1:length(what_to_load)
       
        switch upper(what_to_load{jj})
        case 'NO_PYRAMIDAL'
            if strcmp(type,'PYRAMIDAL')
                load_it = 0;
            end
        case 'NO_INTERNEURON'
            if strcmp(type,'INTERNEURON')
                load_it = 0;
            end
        case 'NO_OTHER'
            if strcmp(type,'OTHER')
                load_it = 0;
            end
        otherwise
            error('Unknown load restriction. ')
        end
    end
    if load_it
        %if isempty(a_ts);
        %    a_ts = ts;
        %end
        ca_of_ts_objects{count} = a_ts;
        count = count + 1;
    else
        disp([num2str(get(a_ts,'object_ID')) ' ' type ' not loaded.'])
    end
    
end
