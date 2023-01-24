function [T,T2] = DLC_Filter (coords,DLCinit,video,outfile2,ts_uS,rat,session)
%%% Jordan 2020

import lib.*;
gpu = 0; %%% Is GPU installed? 1 = yes 0 = no



PXthresh = 10;%120;
LHthresh = 0.50;%
win_size= 10;%40
cutoffFreq=12;%40Hz

minGoodVals=ceil(367/2);
lowPassPad=20;


sz = size(coords);
len = sz(1);
wid = sz(2);







AppendageNames = {'Nose' 'LeftPaw' 'RightPaw'};




Appendage = [];
for i = 1:1:length(AppendageNames)
    
    switch gpu
        case true
            Appendage.(AppendageNames{i}).xyl = gpuArray(zeros(len,3));
        case false
            Appendage.(AppendageNames{i}).xyl = zeros(len,3);
    end
end


%%% populate the digit arrays by iterating through DigitNames array
%%% 'col' variable passes which column of the original csv matrix to assign
%%% from


%%
fprintf("Filtering with parameters:\nMoving Median Pixel Threshold %d\nLikelihood Threshold %.4f\nMoving Median window %d frames\nLow-Pass Filter Cutoff Frequency %dHz\nMinimum length of good valued points %d\nChange parameters in DeepLabCut_Filter function\n",...
    PXthresh, LHthresh, win_size,cutoffFreq,minGoodVals)
pause(5);
fprintf('Now populating digit arrays\n')

col = 2;
for i=1:1:length(AppendageNames)
    
    %%% XYL matrix corresponds to x vals, y vals, and likelihood values
    %%% respectively
    fprintf('Now on digit: %s\n',AppendageNames{i})
    [Appendage.(AppendageNames{i}).xyl,col] = populate(Appendage.(AppendageNames{i}).xyl,col,coords);
    
    
    
end
clear col


%%
%%% check likelihood and eliminate low values
fprintf('Now filtering based on likelihood\n')
for i=1:1:length(AppendageNames)
    
    fprintf('Now on digit: %s\n',AppendageNames{i})
    Appendage.(AppendageNames{i}).xyl = LHcheck(Appendage.(AppendageNames{i}).xyl,LHthresh);
    
    
end

%%
%%% compare values to moving median and eliminate values out of pxthres
fprintf('Now filtering based on moving median\n')
for i=1:1:length(AppendageNames)
    
    fprintf('Now on digit: %s\n',AppendageNames{i})
    Appendage.(AppendageNames{i}).xyl = medifilt(Appendage.(AppendageNames{i}).xyl,PXthresh,win_size);
    
    
end

% for i=1:1:length(AppendageNames)
%
%
%     nans=isnan(Appendage.(AppendageNames{i}).xyl(:,1));
%     chg=diff(nans);
%     strt=find(chg==1);ends=find(chg==-1);
%     if chg(find(chg,1))==-1
%     strt=vertcat(0,strt);
%     %strt=strt(1:end-1);
%     end
%
%     strt=strt(1:end-1);
%
%     %ends(1:end-1);
%     rngs=(ends-strt);
%     edgs=0:10:500;
%     hist=histcounts(rngs,edgs);
%
%     %figure
%     histogram(rngs,edgs)
% end







%% Create variable with each exteremity and save files
extnames = {'Nose' 'Left' 'Right'};

extremity.Left=Appendage.LeftPaw.xyl(:,1:2);

extremity.Right=Appendage.RightPaw.xyl(:,1:2);

extremity.Nose=Appendage.Nose.xyl(:,1:2);

[path,name,ext]=fileparts(DLCinit);
output_name = join([num2str(video),'FILTERED']);
output_name = join([output_name,ext]);
fileout = fullfile(path,output_name);





frame = coords(1:end,1);




Left_x = extremity.Left(:,1);
Left_y = extremity.Left(:,2);

Right_x = extremity.Right(:,1);
Right_y = extremity.Right(:,2);

Nose_x = extremity.Nose(:,1);
Nose_y = extremity.Nose(:,2);


Time_uSec = coords(:,end);



arima


T = table(frame,...
    Nose_x,Nose_y,...
    Left_x,Left_y,...
    Right_x,Right_y,...
    Time_uSec);

tblNames=T.Properties.VariableNames;

%% 
%interpolate to find missing values
T2 = DeepLabCut_Interpol(T);



T2.Properties.VariableNames={'frame' ...
    'Nose_x' 'Nose_y' ...
    'Left_x' 'Left_y' ...
    'Right_x' 'Right_y' ...
    'Time_uSec'};


tblNames=T2.Properties.VariableNames;


%% Low pass position data
fprintf('Now Low Pass Filtering\n')
Fs=367;
L=height(T2);
f=Fs*(0:(L/2))/L;
for i=2:2:length(tblNames)-1
    fprintf('Now on: %s\n',tblNames{i})
    
    %         S=T.(tblNames{i});
    %
    %         Y=fft(S);P2=abs(Y/L);P1=P2(1:L/2+1);P1(2:end-1)=2*P1(2:end-1);
    %
    ptloc=~isnan(T2.(tblNames{i}));
    
    ptst=(find(diff(ptloc)==1))+1;
    pted=(find(diff(ptloc)==-1));
    
    if pted(1)<ptst(1)
        ptst=[1;ptst];
               
    end
    
    if length(ptst)>length(pted)
        pted=[pted;length(ptloc)];
    end
    
    for j=1:length(ptst)
        
        if ((pted(j)-ptst(j))>(minGoodVals+3+(lowPassPad*2)))
            
            T2.(tblNames{i})(ptst(j)+lowPassPad:pted(j)-lowPassPad)=lowpass(T2.(tblNames{i})(ptst(j)+lowPassPad:pted(j)-lowPassPad),cutoffFreq,Fs,'ImpulseResponse','iir','Steepness',0.5);
            T2.(tblNames{i+1})(ptst(j)+lowPassPad:pted(j)-lowPassPad)=lowpass(T2.(tblNames{i+1})(ptst(j)+lowPassPad:pted(j)-lowPassPad),cutoffFreq,Fs,'ImpulseResponse','iir','Steepness',0.5);
        
             T2.(tblNames{i})(ptst(j):ptst(j)+lowPassPad)=nan;
            T2.(tblNames{i+1})(ptst(j):ptst(j)+lowPassPad)=nan;
            
            T2.(tblNames{i})(pted(j)-lowPassPad:ptst(j))=nan;
            T2.(tblNames{i+1})(pted(j)-lowPassPad:ptst(j))=nan;
        else
            
            T2.(tblNames{i})(ptst(j):pted(j))=nan;
            T2.(tblNames{i+1})(ptst(j):pted(j))=nan;
            
        end
        
    end
    
    
    %Appendage.(AppendageNames{i}).xyl(:,1:2)=lowpass(Appendage.(AppendageNames{i}).xyl(:,1:2),cutoffFreq,Fs,'ImpulseResponse','iir','Steepness',0.95);
    
    %         lp=T.(tblNames{i});
    %         Y=fft(lp);p2=abs(Y/L);p1=p2(1:L/2+1);p1(2:end-1)=2*p1(2:end-1);
    
    %         figure
    %         subplot(2,1,1);plot(S);xlim([0 10]);subplot(2,1,2);plot(lp);xlim([0 10]);
    %         figure
    %         subplot(2,1,1);plot(f,P1);xlim([0 10]);subplot(2,1,2);plot(f,p1);xlim([0 10]);
    %
    
    % % %         figure
    % % %         subplot(2,1,1);plot(t,S);subplot(2,1,2);plot(t,lp);
    % % %         figure
    % % %         subplot(2,1,1);plot(f,P1);xlim([0 10]);subplot(2,1,2);plot(f,p1);xlim([0 10]);
    
    
end

%%


fprintf('Now saving coordinates as .csv file...\n')
writetable(T2,fileout);
writetable(T2,outfile2);


if isfile(fileout)
    fprintf('%s has been created and can be found at %s and %s\n', output_name,fileout, outfile2)
else
    fprintf('%s has not been created\n', output_name)
end




end







