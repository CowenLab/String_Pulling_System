% Post-process NLX system files.
% Run in the data directory. It assumes that there is a batch.txt file for
% clustering in the parent directory.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2008
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process the position data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%process_video_labversion(pwd,[],0,40,120)
load('POS.mat')

EPOCH = Identify_epochs;
save('Epochs.mat','EPOCH')

try
    POS2  = Restrict(POS,EPOCH.ER1);
catch
    POS2  = Restrict(POS,EPOCH.WM1);
end

ZONE  = Identify_zones(POS2,[],'Enter center location for (Door 5 is inside)');
save('Zones.mat','ZONE')
% Create an Event.mat file that has all of the relevant behavioral events.
EVT  = ER_Create_Events_File(EPOCH);

ER_Position_template(POS,EVT,ZONE,EPOCH); %  Create and save the template data.

% Plot the behavior.EVT.Nev.Codes
figure(20)
ER_Monitor_Behavior_EVT(EVT.Nev.AllEvtTimestamps(:),EVT.Nev.Codes);
%ER_Monitor_Behavior_EVT(EVT(:,1),num2cell(EVT(:,2))); % For r02

title(pwd)
saveas(gcf,'Task_performance.png')
%
%G = input('Files to delete');
%%
copyfile('../Batch1.txt',pwd)

% Go through the remaining files and look for the valid and invalid
% channels.
%
d = dir('*.Nst');
for ii = 1:length(d)
    % Read in the first 100 records and nix any channels that have all
    % zeros -
    [t,wv] = Read_nlx_spike_file(d(ii).name,[1 100],4);
    s = sum(sum(wv, 3));
    if any(s==0)
        fp = fopen('Batch1.txt','a');
        if find(s==0) == 1
            str = '0 1';
        else
            str = '1 0';
        end

        fprintf(fp,'--File %s \n',d(ii).name)
        fprintf(fp,'    --ChannelValidity         %s 0 0\n',str)
        fprintf(fp,'    --KKwik_MinClusters       12\n')
        fprintf(fp,'    --KKwik_MaxClusters       22\n\n')

        fclose(fp);
    end
end
% I was going to compress the nst files but the compression ration is maybe
% 80% so not really worth it.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the track.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
startix  = Closest(POS(:,1),EVT.E.Trigger_Doors(1));
endix    = Closest(POS(:,1),EVT.E.Trigger_Doors(end));
figure(21)
subplot(2,1,1)
plot(POS(startix:endix,2),POS(startix:endix,3),'k.')
axis tight
title(pwd)
subplot(2,1,2)
plot(POS(startix:endix,1),POS(startix:endix,2),'r.'); hold on
plot(POS(startix:endix,1),POS(startix:endix,3),'k.')
axis tight
saveas(gcf,'Top_Down_Position.png')
close
%%
%dos('C:\Progra~1\WinRAR\winrar.exe a VT1.rar VT1.Nvt &')
% MCLUST
mkdir tfiles
%
if exist('VT1.Nvt','file')
    disp('Zipping the nvt file')
    gzip('VT1.Nvt');
    d = dir('VT1.Nvt');
    if d.bytes > 10000
        delete('VT1.Nvt')
    end
end
delete VT1.smi
delete VT1.mpg

%addpath(genpath('C:\Cowen\Src\matlab\MClustSE_v3.1_temp'))
%RunClustBatch2('Batch1.txt')
%RunClustBatch2('Batch1.txt','JustCreateFDFiles', 1)
