%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add appropriate paths including this directory and the CowenLib
% Directory.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(0, 'defaultTextInterpreter', 'none');
set(0, 'defaultLegendInterpreter', 'none');
set(0, 'defaultAxesTickLabelInterpreter', 'none');
set(0, 'defaultAxesFontName', 'Arial');
format short g

%addpath(genpath(pwd))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dependencies = fullfile(pwd,'.','SupportingFunctions');

if exist(dependencies,'dir')
    addpath(genpath(dependencies))
else
    error('Could not find the Supporting Code directory on your computer.')
end

dbstop if error
set(0, 'defaultFigureColormap', jet);


disp('>>>> Added LID and Supporting function paths. <<<<')