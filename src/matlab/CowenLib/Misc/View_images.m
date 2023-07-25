function View_images(file_parts)
% Brings up all files you specify in file_parts in separated instances of irfanview.
% INPUT: a file name or wildcard pattern.
% OUTPUT: irfanview with the files cued up.
% 
irfanview_path = 'U:\bin\IView';
cmd = ['!' fullfile(irfanview_path,'i_view32.exe') ' ' pwd ' /filepattern="' file_parts '"' ' &'];
eval(cmd)
