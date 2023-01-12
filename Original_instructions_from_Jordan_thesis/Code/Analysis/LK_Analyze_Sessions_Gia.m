%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script loads the master session database and allows 
% you to select the subset of sets to analyze and the analysis 
% function.
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global DIRS
% Set up the locations for all of the important directories and files.
% Do not create new DIRS varibles unless we all agree upon them
DIRS.Data_Dir = 'C:\Users\Sam.Jordan\Box\Cowen Laboratory\Data\LID_Ketamine_Single_Unit_R56';
DIRS.Box_Dir = 'C:\Users\Sam.Jordan\Box\Cowen Laboratory';
DIRS.Analysis_Dir = 'C:\Temp\TempAnaResults';
DIRS.SessionList_File = 'C:\Users\Sam.Jordan\Box\Cowen Laboratory\!Projects\LID_Ketamine_Single_Unit_R56\Meta_Data\SessionInfo.xlsx';
DIRS.LFP_Dir = '';
DIRS.Video_Dir = '';



addpath(genpath('G:\GitHub\LID_Ketamine_String_Pulling\Questions_Gia'))
addpath(genpath('G:\GitHub\CowenLib'))
addpath(pwd)
addpath(genpath('C:\Users\Sam.Jordan\Box\Cowen Laboratory\!Projects\Intan_system\Src\matlab'))


ALLSES = LK_Load_SessionList_File(DIRS.SessionList_File);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Enter the analysis code from the Questions folder.
% AND select the appropriate sessions to analyze.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ana_function=@Q5_Where_Do_Neurons_Fire;
%ana_function=@Q6_When_Do_Neurons_Fire_After_Events;
%ana_function=@Q7_What_Are_Segment_Kinematics;
ana_function=@Q8_How_Do_Ensembles_Behave;
GIX = ALLSES.Sorted & ALLSES.DeepLabCutFile; % Most sessions > 18 are current messed up due to errors with the naming conventions or missing files.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ana_function = @Q2_Do_neurons_correlate_with_string_pulling;
% %  GIX = ALLSES.StringPulling;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run the chosen function on ALL of these sessions.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Running on...')
ALLSES(GIX,:)
LK_Session_Iterator(ana_function, ALLSES(GIX,:))
