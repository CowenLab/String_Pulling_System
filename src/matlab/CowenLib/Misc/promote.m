function promote(mfile,subdir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%function promote(mfile,subdir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Promote a file to the new, clean working directory.
% (move the file to the 'Promoted' subdirectory or a
% subdirectory within the subdirectory.)
%
% INPUT: mfile - the function to move (no need for a .m at the end).
%        subdir - name of the subdirector to place the file (e.g. 'IO')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 0
    % Show the promoted directory - may help you decide which directory to
    % put the file into.
    ls(fullfile(home_dir,'Promoted'))
end
if nargin ==1
    subdir = [];
end
fullpth = which(mfile)
destpth = fullfile(home_dir,'Promoted',subdir,mfile)
status = copyfile(fullpth, destpth);
if status == 1
    % successful.
    delete(fullpth)
    msgbox(['Deleted ' fullpth])
else
    error('COULD NOT COPY FILE!')
    fullpth
    destpth
end


