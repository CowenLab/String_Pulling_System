function sysout = copyfile_xcopy(in_file, out_file)
% matlab's copyfile just does not work sometimes. Use xcopy.
% Cowen 2022
if ~isfile(out_file)
    system(sprintf('copy NUL %s',out_file))
end
sysout = system(sprintf('xcopy %s %s /Y /I',in_file,out_file));
