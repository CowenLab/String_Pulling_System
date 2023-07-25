function D = Box_dir()
[~,username] = dos('ECHO %USERNAME%');
D = ['C:\Users\' username(1:end-1) '\Box\Cowen Laboratory'];
% C:\Users\Stephen Cowen\Box\Cowen Laboratory\!Projects\DeepLabCut_CowenLabMods\MonkeyFaces