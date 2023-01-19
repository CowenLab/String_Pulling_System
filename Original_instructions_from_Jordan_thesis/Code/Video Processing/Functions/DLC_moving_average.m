

i = 0;
col = 1;
avgwidth = 100;
avgin = avgwidth/2;
DLCinit = 'G:\StringPulling_Training_log\315\videos\Recording vids\18\18\18DLC_resnet50_Digit Tracking +Nov22shuffle1_1030000.csv'
selvar = [14,15,16,29,30,31];
opts = detectImportOptions(DLCinit);
opts.SelectedVariableNames=selvar;
M = readmatrix(DLCinit,opts)
size = size(M);
len = size(1);
wid = size(2);


for i=0 : 1 : len
    for col=1 : 1 : wid
        if i < avgin
            
    end
end
