function INTAN_Wavelet(seshfile,sFreq,samples_before,samples_after,iPeth,SAVE_PATH)
%% Define variables
sr = sFreq;
trials = 1;
min_freq = 5;
max_freq = 200;
num_frex = 100;
times = (-samples_before:1:samples_after);
negcscale = -15;
poscscale = 10;

%% Setup a subfolder to save figs
    curfolder = pwd;
    cd .\Validation_Figures                    %%Get in the right subdirectory
        cd (num2str(SAVE_PATH))
        if ~exist('MorletWavelet','dir')          %%Make the PMTM_Plots top dir 
            mkdir 'MorletWavelet';
        end
    cd (num2str(curfolder));                   %%Get back to yo place to do work 

%% Pre-allocate space
for ii = 1:15 %Increase as needed
    eegpower(:,:,ii) = zeros(num_frex,length(seshfile.PETH_W.M))*nan;
    sprintf('Currently allocating space for %d trials',ii)
end
ave_eegpower = eegpower(:,:,1);

%% Run morlet wavelet convolution
for iTrials = 1:1:Rows(seshfile.PETH_W.M)
    MorletWaveletConvolution(seshfile.PETH_W.M(iTrials,:),times,sr,trials,min_freq,max_freq,num_frex); 
    eegpower(1:num_frex,1:length(seshfile.PETH_W.M),iTrials) = ans.eegpower;
end

%% Average output
for iFreq = 1:num_frex
    for iTime = 1:length(seshfile.PETH_W.M)
        ave_eegpower(iFreq,iTime) = nanmean(eegpower(iFreq,iTime,:));
        Update = sprintf('Dobby is currently averaging EEG power for frequency %d/%d and time %d/%d for his master',iFreq,num_frex,iTime,length(seshfile.PETH_W.M))
    end
end

frex = logspace(log10(min_freq),log10(max_freq),num_frex);

%% Plot dat sheeit
figure
contourf(times,frex,ave_eegpower,40,'linecolor','none')
set(gca,'clim',[negcscale poscscale], 'yscale','log','ytick',...
        logspace(log10(min_freq),log10(max_freq),6),'yticklabel',...
        round(logspace(log10(min_freq),log10(max_freq),6)*10)/10)
xlabel('Time (ms)'); ylabel('Frequency (Hz)');
title(['Morlet Wavelet for LFP' num2str(iPeth)])
colorbar

%% Save it to it's place
saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\MorletWavelet' '\Wavelet' num2str(poscscale) 'to' num2str(negcscale) '_' num2str(iPeth)],'png')
close
end