%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Morlet Wavelet for every ripple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cleanup;
disp('Tally-ho'); %I've had enough of your backtalk, Matlab

%%Variables
length_range = [550 550];
sr = 2200; %sampling rate
trials = 1;
min_freq = 80;
max_freq = 180;
num_frex = 30;

%Pre-allocate
Young_convs(1:50000,1) = {zeros(num_frex,length_range(1,2))*nan};
Old_convs = Young_convs;

% Young_raw_trace = zeros(100000,length_range(1,2))*nan;
% Old_raw_trace = Young_raw_trace;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Convolve ripples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd('E:\JP\Lesley Data (original)\Lipa-HDD\Eyeblink_Cut-Data\New_processed_data\Processed_Data');
dirlist = dir;
dirlist = {dirlist(:).name}; %gets the names of all mat files in hur

%%Check whether all files have the necessary components
File_viability = (1:length(dirlist)-2)'*nan;
for iFile_viability = 3:1:length(dirlist)-3
    filename = fullfile(pwd, dirlist(iFile_viability));
    seshfile = load(filename{1}); %loads the file
    if isfield(seshfile,'OUT') == 1 %shit file
        File_viability(iFile_viability) = 0;
    elseif isfield(seshfile,'OUT') == 0 %good file
        File_viability(iFile_viability) = 1;
    end
    sprintf('A moment good sir, currently attending to the viability of file %d',iFile_viability)
end
File_viability = find(File_viability ==1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%On new ripinfo files, run this first
% %%Sleep
% dirlist = dir;
% dirlist = {dirlist(:).name}; %gets the names of all files in hur
% for ii = 1:1:length(File_viability) %gets just the mat files
%     a = fullfile(pwd, dirlist{File_viability(ii)});
%     ripfile = load(a);
%     epochranges = [1, length(ripfile.RF{1}.Std); 0,0; length(ripfile.RF{1}.Std)+1, length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std); length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std)+1, length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std)+length(ripfile.RF{4}.Std); 0, 0; length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std)+length(ripfile.RF{4}.Std)+1, length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std)+length(ripfile.RF{4}.Std)+length(ripfile.RF{6}.Std)];
%     for xx = [1 3 4 6] %gets the sleep epochs
%         %Sleep
%         ripfile.RF{xx}.Sleep = []; %Where 1 for sleep, 0 for waking will go
%         IX = ripfile.rip_movement_SpdEMG(:,2) <= .0000078 & ripfile.rip_movement_SpdEMG(:,3) <= 6; %if their body and eyes aren't moving...
%         IX = IX(epochranges(xx,1):epochranges(xx,2),1)
%         ripfile.RF{xx}.Sleep = double(IX)
%     end
%     RF = ripfile.RF;
%     save(a,'-append','RF')
% end
% 
% %%Ultimately, good ripples
% dirlist = dir;
% dirlist = {dirlist(:).name}; %gets the names of all files in hur
% for ii = 1:1:length(File_viability) %gets just the mat files
%     a = fullfile(pwd, dirlist{File_viability(ii)});
%     ripfile = load(a);
%     epochranges = [1, length(ripfile.RF{1}.Std); 0,0; length(ripfile.RF{1}.Std)+1, length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std); length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std)+1, length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std)+length(ripfile.RF{4}.Std); 0, 0; length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std)+length(ripfile.RF{4}.Std)+1, length(ripfile.RF{1}.Std)+length(ripfile.RF{3}.Std)+length(ripfile.RF{4}.Std)+length(ripfile.RF{6}.Std)];
%     for xx = [1 3 4 6] %gets the sleep epochs
%         ripfile.RF{xx}.Good = [];
%         %Good ripples
%         IX = ripfile.RF{xx}.RipQualityRipToHGammaRatio>1.3 & ...
%             ripfile.RF{xx}.Sleep==1 & ...
%             ripfile.RF{xx}.PeakRipDeflection > 780 & ripfile.RF{xx}.PeakRipDeflection < 820 &...
%             ripfile.RF{xx}.TimeFromRestOnset_sec(:,1) < 4000;
%         ripfile.RF{xx}.Good(:,1) = real(IX)
%     end
%     RF = ripfile.RF;
%     save(a,'-append','RF')
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%Compile all the ripples for young and old
young_rip_place = 1;
old_rip_place = 1;
for iFile = 1:1:length(File_viability)
    filename = fullfile(pwd, dirlist(File_viability(iFile)));
    seshfile = load(filename{1}); %loads the file
    for iEpochs = [1 3 4 6]
        good_rips = [find(seshfile.RF{iEpochs}.Good==1)]';
        for iRip = 1:1:length(good_rips)
            
            %%Sort young vs old
            if seshfile.ses.group == 'yng' & ...
                    length(cell2mat(seshfile.RIPS{iEpochs}.filt_rips(good_rips(iRip)))') >= length_range(1,1) &...
                    length(cell2mat(seshfile.RIPS{iEpochs}.filt_rips(good_rips(iRip)))') <= length_range(1,2)
                %Then
                data = cell2mat(seshfile.RIPS{iEpochs}.filt_rips(good_rips(iRip)))';
                times = seshfile.RIPS{iEpochs}.x_msec{good_rips(iRip)}(221:(end-221));
                eegpower = MorletWaveletConvolution(data,times,sr,trials,min_freq,max_freq,num_frex);
                Young_convs{young_rip_place}(1:Rows(eegpower.eegpower),1:Cols(eegpower.eegpower)) = eegpower.eegpower;
                young_rip_place = young_rip_place+1;
                
            elseif seshfile.ses.group == 'old' & ...
                    length(cell2mat(seshfile.RIPS{iEpochs}.filt_rips(good_rips(iRip)))') >= length_range(1,1) &...
                    length(cell2mat(seshfile.RIPS{iEpochs}.filt_rips(good_rips(iRip)))') <= length_range(1,2)
                %Then
                data = cell2mat(seshfile.RIPS{iEpochs}.filt_rips(good_rips(iRip)))';
                times = seshfile.RIPS{iEpochs}.x_msec{good_rips(iRip)}(221:(end-221));
                eegpower = MorletWaveletConvolution(data,times,sr,trials,min_freq,max_freq,num_frex);
                Old_convs{young_rip_place}(1:Rows(eegpower.eegpower),1:Cols(eegpower.eegpower)) = eegpower.eegpower;
                old_rip_place = old_rip_place+1;
            end
            
            %%Grab max times
            if length(cell2mat(seshfile.RIPS{iEpochs}.filt_rips(good_rips(iRip)))') == length_range(1,2)
                TF_times = seshfile.RIPS{iEpochs}.x_msec{good_rips(iRip)}(221:(end-221));
            end
            
            Update = sprintf('Yet another moment good sir, currently convoluting ripple %d/%d of epoch %d/6 of file %d/%d',iRip,length(seshfile.RIPS{iEpochs}.filt_rips),iEpochs,iFile,length(File_viability))
        end
    end
end


%%UPDATE: CREATE A 3D ARRAY
%%Average out (YOUNG)
for iFreq = 1:num_frex
    for iTime = 1:length_range(1,2)
        averaging = [];
        for iBlock = 1:length(Young_convs)
            averaging = [averaging; Young_convs{iBlock}(iFreq,iTime)];
            Update = sprintf('One last thing good sir, currently averaging the Young EEG power for frequency %d/%d and time %d/%d of file %d/%d',iFreq,num_frex,iTime,length_range(1,2),iBlock,length(Young_convs))
        end
        ave_eegpower_young(iFreq,iTime) = nanmean(averaging);
    end
end

% %%Average out (OLD)
% for iFreq = 1:num_frex
%     for iTime = 1:length_range(1,2)
%         averaging = [];
%         for iBlock = 1:length(Old_convs)
%             averaging = [averaging; Old_convs{iBlock}(iFreq,iTime)];
%             Update = sprintf('One last thing good sir, currently averaging the Old EEG power for frequency %d/%d and time %d/%d of file %d/%d',iFreq,num_frex,iTime,length_range(1,2),iBlock,length(Young_convs))
%         end
%         ave_eegpower_old(iFreq,iTime) = nanmean(averaging);
%     end
% end
% 
% C = {[1 2 3; 1 2 3; 1 2 3], [1 2 3; 1 2 3; 1 2 3], [1 2 3; 1 2 3; 1 2 3]};
% Cmeans = cellfun(@mean, C,'UniformOutput', false);
% 
% var_mean = cellfun(@mean, x, 'UniformOutput', false); %columnwise mean value
% var_mean = cellfun(@(in) mean(in(:)), x); %% mean value of the total "subcell"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Young vs Old
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% frex = logspace(log10(min_freq),log10(max_freq),num_frex);
% 
% figure
% subplot(2,1,1)
% contourf(TF_times',frex,ave_eegpower_young,40,'linecolor','none')
% set(gca,'clim',[-5 5]) %, 'yscale','log','ytick',...
% %         logspace(log10(min_freq),log10(max_freq),6),'yticklabel',...
% %         round(logspace(log10(min_freq),log10(max_freq),6)*10)/10)
% xlabel('Time (ms)'), ylabel('Frequency (Hz)')
% title([ num2str(condition) 'Channel ' num2str(i) ])
% 
% subplot(2,1,2)
% contourf(TF_times',frex,ave_eegpower_old,40,'linecolor','none')
% set(gca,'clim',[-5 5]) %, 'yscale','log','ytick',...
% %         logspace(log10(min_freq),log10(max_freq),6),'yticklabel',...
% %         round(logspace(log10(min_freq),log10(max_freq),6)*10)/10)
% xlabel('Time (ms)'), ylabel('Frequency (Hz)')
