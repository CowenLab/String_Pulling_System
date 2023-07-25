function [C] = NbClust_R(INPUT)
%function [C] = NbClust_R(INPUT)
%
% Wrapper for the R routine of the same name.
% See the .R file for details on the R algorithm used.
%
% Lots of assumptions and preliminaries go into running this function:
%
% This assumes Windows and that you have a C: drive and that you have a 
% C:\Program Files\R\R directory and that you have installed the NbClust R
% package in R.
%
% INPUT: a nSample by nFeature matrix of data
% OUTPUT: a nSample vector of classification IDs
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cowen 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R_file = 'NbClust.R'; % The R file you wrote. This must live in the directory where this .m file lives.
d = dir('C:\Program Files\R\R-*'); % The executable directory for R
if length(d) > 1
    d.name
    disp('More than one R program file directory detected. You may want to delete one.')
end
R_path_and_exec = ['C:\Program Files\R\' d(1).name '\bin\x64\Rscript.exe']; % this has to be hard coded - perhaps there is an env variable, but this works.
if ~exist(R_path_and_exec,'file')
    disp(R_path_and_exec)
    error('Could not find the path to Rscript.exe')
end
p = which('NbClust_R');
p = fileparts(p); % find the path to the .R file associated with this .m file

if ~exist('C:\Temp','dir')
    mkdir('C:\Temp');% R has a tempdir() but this is easier for now.
end
fname = fullfile('C:\Temp','R_input.txt'); % R has a tempdir() function as well, but it appends some extra crap at the end so easier for now to just hardcode.
result_fname = fullfile('C:\Temp','R_output.txt');
if exist(result_fname,'file')
    delete(result_fname)
end
% Verify that it was actually deleted... We should not need to do this, but
% it is for safety. 
if exist(result_fname,'file')
    result_fname
    error('Could not delete')
end
% Write the data to a temporary text file.
csvwrite(fname,INPUT);
% Call R which will operate on this file.
cmd = [ '"' R_path_and_exec '" "' fullfile(p,R_file) '"' ];
status = system(cmd); % Executing this sometimes gives:... NbClust_R.m' could not be cleared because it contains MATLAB code that is currently executing
pause(0.01); 
if status ~= 0
    % error
    error('Failed to execute system command. Error %d \n %s',status,cmd)
end
% load the results but wait until the file is ready
while(~exist(result_fname,'file'))
    pause(0.01)
end
% Load the results
C = load(result_fname);
if length(C) == 1 || C(1) == -1
    % This indicates that an error occurred.
    C = [];
end
% Clust_IDs = unique(C);
