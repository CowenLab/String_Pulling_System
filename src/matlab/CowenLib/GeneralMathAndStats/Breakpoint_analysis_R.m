function [breakpoints, confidence_p] = Breakpoint_analysis_R(TIMESER)
%function bp = Breakpoint_analysis_R(TIMESER)
% Wrapper for a R routine.
%
% Finds the point in the time series when things changed...
% Requires R installed in the Program Files directory (see path)
%
% Yes, I know that this is the world's most inefficient way to implement
% this (calling R separately each time), but it's the easiest, and I could
% not get the R-Link D COM thing to work (maybe because I was using 64 bit
% R). 
%
% Cowen 2011 
p = which(mfilename);
p = fileparts(p); % find the path
p = fullfile(p,'R');
R_path_and_exec = '"C:\Program Files\R\R-2.14.0\bin\x64\Rscript.exe"';

% Test the data with the change point analysis.
fname = 'C:\Temp\R_input.txt';
result_fname = 'C:\Temp\R_output.txt';
breakpoints = zeros(Rows(TIMESER),1)*nan;
confidence_p = zeros(Rows(TIMESER),1)*nan;
fullfile(p,'Breakpoint_analysis.R')
for ii = 1:Rows(TIMESER)
    % Write the data to a temporary text file.
    delete(result_fname)
    
    fp = fopen(fname,'w');
    fprintf(fp,'DataFromML\n');
    fprintf(fp,'%d\n',TIMESER(ii,:)');
    fclose(fp);
    
    % Call R which will operate on this file.
    system([R_path_and_exec ' ' fullfile(p,'Breakpoint_analysis.R')]);

    % load the results but wait until the file is ready
    while(~exist(result_fname,'file'))
    end
    fp = fopen(result_fname,'r');
    fgetl(fp);
    o = fgetl(fp);
    fgetl(fp);
    pval = fgetl(fp);
    fclose(fp);
    
    breakpoints(ii) = str2double(o(5:end));
    pval = strrep(pval,'"S0"','');
    confidence_p(ii) = str2double(pval);
    %R = load(result_fname,'-ascii');
    
end