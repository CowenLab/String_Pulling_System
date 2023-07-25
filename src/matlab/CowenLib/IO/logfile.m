function logfile(textstr,fname)
% function logfile(textstr,fname)
% Writes a text string to the default log file.
if nargin < 2
    fname = 'ANALYSIS_LOGFILE.txt';
end
if nargin == 0 || isempty(textstr)
    % display the logfile
    edit(fullfile(Analysis_dir,fname));
    return
end
disp(textstr)
fp = fopen(fullfile(Analysis_dir,fname),'a');
fprintf(fp,'%s\t%s\n',textstr,datestr(now));
fclose(fp);
