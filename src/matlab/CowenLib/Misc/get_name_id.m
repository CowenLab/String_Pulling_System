function [name, id] = get_name_id(name_string);
% Returns strings.
idx = findstr('_',name_string);
id = name_string(idx+1:end);
name = name_string(1:idx-1);
