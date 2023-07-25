function Create_standalone_directory(target_function,destination_directory)
% Creates a standalone directory for the function in question. This means
% that you only need to have a startup in this directory and the entire
% path will be loaded.
try
    mkdir (destination_directory)
catch
    error('Could not make the destination directory')
end
thisfun = which(target_function);
[p,n,e] = fileparts(thisfun);
copyfile(thisfun, fullfile(destination_directory,[n e]))

tl = depfun(target_function);
for ii = 1:length(tl)
    if findstr(tl{ii},'MATLAB7')
    elseif findstr(tl{ii},'MATLABR')
       
    else
        fprintf('.')
        % It is not a matlab function so copy all of the files to the
        % destinaltion directory.
        [p,n,e] = fileparts(tl{ii});
        copyfile(tl{ii}, fullfile(destination_directory,[n e]))
    end
end
% Create the startup file.
fp = fopen(fullfile(destination_directory,'startup.m'),'w');
fprintf(fp,'addpath(pwd);\n');
fclose(fp)