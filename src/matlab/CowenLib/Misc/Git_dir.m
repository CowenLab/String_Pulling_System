function D = Git_dir()
[~,username] = dos('ECHO %USERNAME%');
D = ['C:\Users\' username(1:end-1) '\Documents\GitHub\'];
% C:\Users\Stephen Cowen\Documents\GitHub\Neural_Ensemble_Detection\matlab\RussoDurstewitz