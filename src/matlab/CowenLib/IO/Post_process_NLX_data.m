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
if exist('VT1.Nvt','file')
    disp('Processing position data.')
    POS = position_from_nvt();
    % Correct the tracker offset. (See Analysis_Labbook_1.doc for my
    % analysiis of this offset.
    offset_usec = 144224;
    POS(:,1) = POS(:,1) - offset_usec;
    save('POS.mat','POS');
else
    load('POS.mat')
    disp('NO VT1.Nvt FILE, assuming it was already processed.')
end

EPOCH = Identify_epochs;
save('Epochs.mat','EPOCH')

try
    POS2  = Restrict(POS,EPOCH.ER1);
catch
    POS2  = Restrict(POS,EPOCH.WM1);
end
ZONE  = Identify_zones(POS2,[],'Enter center location for (Door 5 is inside)')
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

%% Summarize the channels and delete bad ones if there are any.
% Remove all files with few or no spikes
d = dir('*.nst');
for ii = 1:length(d)
    if d(ii).bytes <= 36384
        delete(d(ii).name)
    end
end
%
files = find_files('*.nst');
xl = find_files('DataAcquisition*.xls');
%eval(['!' xl{1} '&' ])
%
fname = findfiles('Data*.xls');
[a,txt,raw] = xlsread(fname{1}, 'B11:B34');
goodSTs = []; % unfortunately, raw is the only way to get it to work.
for ii =1:length(raw)
    if ~ischar(raw{ii})
        if raw{ii} >= 1
            goodSTs = [goodSTs ii];
        end
    end
end
%goodSTs = find(a>=1);
%%
figure
mkdir ClustSum_Images
rw = ceil(length(files)/3);
for iF = 1:length(files)
    [p,n] = fileparts(files{iF});
    fnum = str2double(n(3:end));
    postfix = 'maybe_bad';
    if ismember(fnum,goodSTs);
        % Do nothing, this is a good one.
        postfix = 'good';

    end
    % Needs some double checking.
    loaded = true;
    t = Nlx2MatSpike( files{iF}, [1 0 0 0 0 ], 0, 1, 0 );
    try
        if length(t) > 100000
            disp('big file')
            [t,wv] = Read_nlx_spike_file(files{iF}, t(1:8:end), 1);
        else
            [t,wv] = Read_nlx_spike_file(files{iF}, [], 6);
        end
    catch
        disp([ files{iF} ' Could not load data, skipping'])
        loaded = false;
    end
    if loaded
        % Get rid of outliers.
        s = find(squeeze(wv(8,1,:)<180));
        wv = wv(:,:,s);
        %         clf
        %         set(gcf,'Position',[520 670 835 428])
        %         H= ndhist([squeeze(wv(8,1,1:4:end))';squeeze(wv(8,2,1:4:end))'],[500;500],[1;1],[180;180]);
        %         H2 = conv2(H,hanning(15)*hanning(15)');
        %         subplot(2,2,1)
        %         imagesc(log(H2'));axis xy
        %         disp(files{iF})
        clf
        subplot(2,2,1)

        ac = AutoCorr(t,20,1000); % ts, msec, nbins
        plot(linspace(0,500,length(ac)),ac');
        axis tight
        title([ num2str(iF) '    ' files{iF}])
        set(gcf,'Name',[ num2str(iF) '    ' files{iF}])
        subplot(2,2,2)
        plot(squeeze(wv(8,1,1:2:end)), squeeze(wv(8,2,1:2:end)),'k.','MarkerSize',1)
        axis([0 320 0 320])
        title(files{iF})
        mwv1 = mean(wv(:,1,:),3);
        mwv2 = mean(wv(:,2,:),3);
        axes('Position',[.7, .7 .23 .23])
        plot(mwv1,'r');hold on; plot( mwv2,'b')
        axis off
        %
        h1 = hist(squeeze(wv(8,1,:)),30:2:150);
        h2 = hist(squeeze(wv(8,2,:)),30:2:150);
        axes('Position',[.7, .2 .23 .23])
        plot(h1,'r');hold on; plot( h2,'b')
        axis off

        subplot(2,2,3:4)
        plot(t(s), squeeze(wv(8,1,:)), 'b.','MarkerSize',1)
        hold on
        plot(t(s), squeeze(wv(8,2,:)), 'k.','MarkerSize',1)
        saveas(gcf,['./ClustSum_Images/ClustSum_' n '_' postfix],'png')

        if 0
            K = menu('Delete','Yes','No');
            if K == 1
                K = menu('Are You Sure?','Yes','No');
                if K == 1
                    delete(files{iF})
                end
            end
            close all
            drawnow
        end

    end
end
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

%%% EEG
disp('Zipping the eeg')
gzip({'*.ncs'},'EEG')
delete('*.ncs')
% plot the mic data.
ER_mic_data_plot

%addpath(genpath('C:\Cowen\Src\matlab\MClustSE_v3.1_temp'))
%RunClustBatch2('Batch1.txt')
%RunClustBatch2('Batch1.txt','JustCreateFDFiles', 1)
