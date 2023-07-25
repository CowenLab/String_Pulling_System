# CowenLib
 General purpose code for the Cowen Lab (much code is imported from other sources)
 
 For most things to work in our lab, this folder and all subfolders must be in the Matlab path (e.g., addpath(genpath(pwd)))
 
 I usually put this in my startup.m file. Just change the matlab shortcut on your desktop to 'Start In' some folder that contains a startup.m file. This file can then add the appropriate paths. Also, this code is an example of how to automatically add the Git project folders to your path in your startup.m file...
 
txt = userpath;
ix =  strfind(txt,'Documents');
pth = txt(1:(ix-1));
BOX_DIR = fullfile(pth,'Box','Cowen Laboratory');
GIT_DIR = fullfile(pth,'Documents','GitHub');
PROJECTS_DIR = fullfile(BOX_DIR,'!Projects\');

addpath(genpath(fullfile(GIT_DIR,'CowenLib')))
disp('Added CowenLib')
addpath(genpath(fullfile(GIT_DIR,'LID_Ketamine_String_Pulling')))
disp('Added LID_Ketamine_String_Pulling')
