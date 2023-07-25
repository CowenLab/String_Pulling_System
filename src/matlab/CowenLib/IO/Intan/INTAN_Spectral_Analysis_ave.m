%%%Code for Spectral Analysis of Acute Surgeries
%%%Use this with PETH_EEG_Simple to get correct variables
%%%Uses folder with output from PETH_EEG_Simple to create averaged PMTM
%%%

%%PMTM Code

%Some defining variables, etc
SAVE_FIGURES = true;
PMTM = true;
minFreq = 1;
maxFreq = 175;
spaceFreq = 1.5;
numfreq = round((maxFreq-minFreq)/spaceFreq)+1;

if PMTM
    %% Setup the directories for this, saving all these figures in one folder
    cd .\Validation_Figures_2.5\
    if ~exist('PMTM_Plots','dir')
            mkdir 'PMTM_Plots';
    end
    cd ..\
    
       cd .\Validation_Figures_2.5\PMTM_Plots;
           mkdir (['PMTM_' num2str(iLFP)]);
       cd ..\
    cd ..\
    
    %%Get Pre stim and post stim variables
    PreS = PETH_W.ix < 0;
    PostS = PETH_W.ix > 500; %this seems to work pretty good, but may need to be adjusted for different stims
    %S = ix >= 0 & =< 500;
    
%%Preallocating space for pre-stim    
% % % for xx = 1:20
% % %     Hz_PowerPre(:,:,xx) = zeros(numfreq,length(PreS))*nan;
% % %     sprintf('Currently allocating space for %d time',xx)
% % % end
% % % avgPre = Hz_PowerPre(:,:,1)
% % % 
% % % %Preallocating space for post-stim
% % % for yy = 1:20
% % %     Hz_PowerPost(:,:,yy) = zeros(numfreq,length(PostS))*nan;
% % %     sprintf('Currently allocating space for %d time',yy)
% % % end
% % % avgPost = Hz_PowerPost(:,:,1)
    
    %%run all trials on PMTM
        
        trialnum = num2str(ii);
        
        %%Run PMTM function for pre- and post- stim,
        [prePower,preHz] = pmtm(PETH_W.M(ii,PreS), [], minFreq:spaceFreq:maxFreq,sFreq);
        [postPower,postHz] = pmtm(PETH_W.M(ii,PostS), [], minFreq:spaceFreq:maxFreq,sFreq);
        
        %Backgroun subtract
        [bgPower] = [postPower] - [prePower];
        [bgHz] = [postHz];
        
        %%Create the figure
        figure (ii);
        subplot(2,2,1);
            plot(preHz,10*log10(prePower),'r');
            title(['Plot from PMTM Trial_' trialnum]);
            xlabel('Frequency (HZ)');
            ylabel('dB (10*log10)');

         subplot(2,2,3);
            plot(10*log10(preHz),10*log10(prePower),'r');
            title(['Plot from PMTM Trial_' trialnum]);
            xlabel('Frequency (HZ) (10*log10)');
            ylabel('dB (10*log10)');
      
        subplot(2,2,2);
            plot(postHz,10*log10(postPower),'b');
            title(['Plot from PMTM Trial_' trialnum]);
            xlabel('Frequency (HZ)');
            ylabel('dB (10*log10)');

         subplot(2,2,4);
            plot(10*log10(postHz),10*log10(postPower),'b');
            title(['Plot from PMTM Trial_' trialnum]);
            xlabel('Frequency (HZ) (10*log10)');
            ylabel('dB (10*log10)');
    
            if SAVE_FIGURES
                saveas(gcf,['.\Validation_Figures_2.5\PMTM_Plots\PMTM_' ([num2str(iLFP)]) '\LFP' num2str(iLFP) '_' 'Trial_' trialnum '_'],'png')
                close
            end

end
