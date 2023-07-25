function [f,just_names] = find_files(thepath)
% Finds all files of a given type (wildcards OK) in the current directory.
% does not prepend the full path likd FindFiles.
% cowen 
% 
f = [];
just_names = [];
[p,n,e] = fileparts(thepath);
d = dir(thepath);
pw = pwd;
if ~isempty(p)
    cd( p )
end 
newp = pwd;
count = 1;
for ii = 1:length(d)
    if ~strcmp(d(ii).name,'.') && ~strcmp(d(ii).name,'..')
        f{count} = fullfile(p,d(ii).name);
        just_names{count} = d(ii).name;
        count = count + 1;
    end
end
cd(pw)