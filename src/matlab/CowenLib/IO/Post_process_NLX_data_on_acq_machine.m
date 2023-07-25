% Post-process NLX system files: Limited post-processing for the
% acquisition machine...
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cowen 2010
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Process the position data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%process_video_labversion(pwd,[],0,40,120)
if exist('C:\Data\Putty.log','file')
    copyfile('C:\Data\Putty.log',pwd)    
end
if exist('C:\Data\IMU.log','file')
    copyfile('C:\Data\IMU.log',pwd)    
end

if exist('VT1.Nvt','file')
    disp('Processing position data.')
    POS = position_from_nvt();
    POS_orig = POS;
    POS = Clean_position_data(POS,15,[1 20]);
    % Correct the tracker offset. (See Analysis_Labbook_1.doc for my
    % analysiis of this offset.
    offset_usec = 144224;
    POS(:,1) = POS(:,1) - offset_usec;
    save('POS.mat','POS');
    figure
    subplot(3,2,1:4)
    plot(POS(1:3:end,2),POS(1:3:end,3),'k.-','MarkerSize',1)
    hold on
    plot(POS_orig(1:3:end,2),POS_orig(1:3:end,3),'b.-','MarkerSize',1)
    legend('filtered','original')
    
    title([pwd ' offset usec: ' num2str(offset_usec)])
    
    subplot(3,2,5:6)
    plot(POS(1:3:end,1)/1e6/60,POS(1:3:end,2),POS(1:3:end,1)/1e6/60,POS(1:3:end,3))
    hold on
    plot(POS_orig(1:3:end,1)/1e6/60,POS_orig(1:3:end,2),'r',POS_orig(1:3:end,1)/1e6/60,POS_orig(1:3:end,3),'m')
    xlabel('min')
    axis tight
    saveas(gcf,'POS.png');
    
else
    load('POS.mat')
    disp('Found POS.mat instead of VT1.mat')
end

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
    % I should switch this to the MClust way of reading spikes- so It works
    % on the mac.
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
%%
%G = input('Files to delete');
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

% EEG
% plot the mic data.
[T_mic, MIC_data] = Read_CR_files({'CSC16.ncs'}, 400, [POS(end,1)-30*60*1000000 POS(end,1)-1500000]);
%[T_mic, MIC_data] = Read_CR_files({'EEG/CSC16.ncs'}, 400, [POS(end,1) POS(end,1)-1500000]);
clf
plot(T_mic, MIC_data)
title(['Mic Data   ' pwd])
saveas(gcf,'Mic.png')
    
disp('Zipping the eeg')
mkdir EEG
gzip({'*.ncs'},'EEG')

if exist('EEG/CSC1.ncs.gz','file')
    delete('*.ncs')
end
clf
ER_monitor_Behavior_SerialPort
title([ pwd '  From PUTTY LOG FILE'])
saveas(gca,'Task_performance_from_log.png')
%ER_monitor_Behavior_EVT_2
%title([pwd '  From Nev FILE'])
%saveas(gca,'Task_performance_from_nev.png')
% Copy the depth sheet into this directory.
copyfile('../Electrode_Depth*.xls',pwd)
% Make backup copies of the data.
dest_dir1 = 'G:/CHEETAH BACKUP/r14';
copyfile(pwd,dest_dir1)


%disp('Data Copied')

%addpath(genpath('C:\Cowen\Src\matlab\MClustSE_v3.1_temp'))
%RunClustBatch2('Batch1.txt')
%RunClustBatch2('Batch1.txt','JustCreateFDFiles', 1)
