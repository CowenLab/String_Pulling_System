function Data_archive(destination_dir, source_code_dir, m_file_name)
% Archive the data for this analysis.
%
% INPUT:  destination directory, present working directory, m file name to archive.
% OUTPUT: NONE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BTW: There is a stupid ideosyncracy in matlab: if you try to make a directory when your
% current directory is in a network folder, it barfs. You have to be on a real physical drive
% to make a directory. This implementation gets around the problem.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ppp = pwd;
% Oh the matlab wierdness...
if isempty(strfind('MACI',computer))
    cd C:
end
% Make a directory for the data. (This may look strange but because of matlab ideosyncracies, it's the only thing I could get to work.

[p1,n1,e] = fileparts(fileparts(fileparts(destination_dir)));
[p2,n2,e] = fileparts(fileparts(destination_dir));
[p3,n3,e] = fileparts(destination_dir);
cd (p1)
if ~exist(n1,'dir')
    s = mkdir (n1);
end
cd (p2)
if ~exist(n2,'dir')
    s = mkdir (n2);
end
cd (p3)
if ~exist(n3,'dir')
    s = mkdir (n3);
end
cd (n3)
if ~exist('Figures','dir')
    s = mkdir ('Figures');
end
if (0)
    cd (fileparts(fileparts(fileparts(destination_dir))))
    mkdir (n1)
    eval(['mkdir ' fileparts(fileparts(destination_dir))])
    cd (fileparts(fileparts(destination_dir)))
    eval(['mkdir ' fileparts(destination_dir)])
    cd (fileparts(destination_dir))
    eval(['mkdir ' destination_dir])
    cd (fileparts(fileparts(fileparts(destination_dir))))
    eval(['mkdir ' fileparts(fileparts(destination_dir))])
    s = mkdir(fileparts(fileparts(fileparts(destination_dir))),fileparts(fileparts(destination_dir)));
    s = mkdir(fileparts(fileparts(destination_dir)),fileparts(destination_dir));
    s = mkdir(fileparts(destination_dir),destination_dir);
    s = mkdir(destination_dir,'Figures');
end
% copy the .m file responsible for the analysis to the destination directory.
try
    copyfile(fullfile(source_code_dir,[m_file_name ]), fullfile(destination_dir,  [ m_file_name '.archive' ]));
catch
    disp('Could not copy files. It may be open.')
end
% Copy all doc files.
% Get rid of the word temp files. They annoy me.
delete ~*.doc
d = dir(fullfile(source_code_dir,[m_file_name(1:4) '*.doc']));
for ii = 1:length(d)
    copyfile(fullfile(source_code_dir, d(ii).name), fullfile(destination_dir, d(ii).name),'f');
end
% 
cd (ppp)

