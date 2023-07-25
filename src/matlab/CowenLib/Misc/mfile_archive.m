function mfile_archive(mfile_name)
%function mfile_archive(mfile_name)
%
% Archive the passed in mfile. All data is stored in
% M_file_analysis_archive which rests in my matlab directory.
%
% INPUT: Mfile name to be archived.
% OUTPUT: none.
% 
% ASSUMES that my root source code directory is the Working directory where
% Data_archive is stored. This should be right 99.9% of the time.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen (2006)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
w = which(mfilename); % this function must exist - I'm it!
[dest_p,n,e] = fileparts(w);
dest_p = strrep(dest_p,'Working','M_file_analysis_archive');
w = which(mfile_name);
[mfile_p,mname,mext] = fileparts(w);

if ~exist(dest_p,'dir')
    try 
        mkdir(dest_p);
    catch
        error('Could not make M_file_analysis_archive')
    end
end
% Copy the file. Only saves it once per hour to avoid explosion in files.
try
    % Just save the data- not the time - one file saved per day should be
    % more than enought - fights an insane increase in filesize.
    copyfile(w,fullfile(dest_p,[mname '_' datestr(now,'dd-mmm-yyyy') '.m']),'f');
catch
    disp([mfilename ': Could not copy ' mfile_name '.'])
end