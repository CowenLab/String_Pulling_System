function INTAN_Spectral_Analysis (seshfile,sFreq,iPeth,SAVE_PATH)

%%%Code for Spectral Analysis of Acute Surgeries
%%%Use this with PETH_EEG_Simple to get correct variables

%%PMTM Code

%%***Altered Validation Figures directories for INTAN_Validate_Data2 -- 07282014

%Some defining variables, etc
SAVE_FIGURES = true;
PMTM = true;
minFreq = 1;
maxFreq = 200;
numfreq = 100;
spaceFreq = ((maxFreq-minFreq)/numfreq);

sMinFreq = 1;
sMaxFreq = 55;
sNumfreq = 25;
sSpaceFreq = ((sMaxFreq-sMinFreq)/sNumfreq);

if PMTM
    %% Setup the directories for this, saving all these figures in one folder
    curfolder = pwd;
    cd .\Validation_Figures                    %%Get in the right subdirectory
    cd (num2str(SAVE_PATH))
    if ~exist('PMTM_Plots','dir')          %%Make the PMTM_Plots top dir
        mkdir 'PMTM_Plots';
    end
    cd 'PMTM_Plots'                        %%Make a folder for ea LFP ch
    if ~exist (['PMTM_' num2str(iPeth)],'dir')
        mkdir (['PMTM_' num2str(iPeth)]);
    end
    cd (num2str(curfolder));                   %%Get back to yo place to do work
    
    %%Find exact timing of stimulus
    open StimStarts_EVT.mat;
        StimEpoch = ans;
        StimLength_usec = abs(StimEpoch.UpTransitions_usec - StimEpoch.DownTransitions_usec);
        StimTime_usec = max(StimLength_usec);
    
    %%Get Pre stim and post stim variables
    PreS = seshfile.PETH_W.ix < 0;
    PostS = seshfile.PETH_W.ix > 500; %this seems to work pretty good, but may need to be adjusted for different stims
    
    %%run all trials on PMTM
    trials = size(seshfile.PETH_W.M);
    trials = trials(1);
    for ii = 1:trials
        trialnum = num2str(ii);
        
        %%Run PMTM function for pre- and post- stim,
        [prePower,preHz] = pmtm(seshfile.PETH_W.M(ii,PreS), [], minFreq:spaceFreq:maxFreq,sFreq);
        [postPower,postHz] = pmtm(seshfile.PETH_W.M(ii,PostS), [], minFreq:spaceFreq:maxFreq,sFreq);
        
        %%Store PMTM prePower out to average
        Pre(ii,:) = prePower;
        
        %%Store PMTM postPower out to average
        Post(ii,:) = postPower;
        
    end
    
    %Average the PMTM power out
    avgPre = mean(Pre);
    avgPost = mean(Post);
    
    %%Create the figure
    figure (iPeth);
    subplot(2,2,1);
    plot_confidence_intervals(preHz,10*log10(Pre),[],'r')
    title(['Plot from average pre stim PMTM' num2str(iPeth)]);
    xlabel('Frequency (HZ)');
    ylabel('dB (10*log10)');
    
    subplot(2,2,3);
    plot_confidence_intervals(10*log10(preHz),10*log10(Pre),[],'r');
    title(['Plot from average pre stim PMTM' num2str(iPeth)]);
    xlabel('Frequency (HZ) (10*log10)');
    ylabel('dB (10*log10)');
    
    subplot(2,2,2);
    plot_confidence_intervals(postHz,10*log10(Post),[],'b');
    title(['Plot from average post stim PMTM'  num2str(iPeth)]);
    xlabel('Frequency (HZ)');
    ylabel('dB (10*log10)');
    
    subplot(2,2,4);
    plot_confidence_intervals(10*log10(postHz),10*log10(Post),[],'b');
    title(['Plot from average post stim PMTM' num2str(iPeth)]);
    xlabel('Frequency (HZ) (10*log10)');
    ylabel('dB (10*log10)');
    
    if SAVE_FIGURES
        saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\PMTM_Plots\PMTM_' ([num2str(iPeth)]) '\LFP' num2str(iPeth) '_' 'AverageTrials' ],'png')
        close
    end
    
    %%Create figure with substraction
    figure (iPeth+100);
    plot_confidence_intervals(preHz,(log10(Post)-log10(Pre)),[],'k');
    hold on
    a = axis;
    plot(a(1:2),[0 0 ],'r:')
    title(['PMTM Subtraction for LFP channel ' num2str(iPeth) ' in striatum at 2.8mm DV']);
    xlabel('Frequency (HZ)');
    ylabel('dB (log10)');
   
    if SAVE_FIGURES
        saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\PMTM_Plots\PMTM_' ([num2str(iPeth)]) '\LFP' num2str(iPeth) '_' 'PMTM_Subtraction' ],'png')
        close
    end
    
   %%Create figure with overlays
    figure (iPeth+200);
    subplot(2,1,1);
    plot_confidence_intervals(preHz,10*log10(Pre),[],'r');
        title(['Average PMTM for LFP Channel ' num2str(iPeth) ' at 7.3mm']);
        xlabel('Frequency (HZ)');
        ylabel('dB (10*log10)');
        legend('PreStim','PostStim')
        hold on
    plot_confidence_intervals(postHz,10*log10(Post),[],'b');
        title(['Plot from average PMTM for LFP Ch:' num2str(iPeth)]);
        xlabel('Frequency (HZ)');
        ylabel('dB (10*log10)');
        legend('PreStim','PostStim')
    
    subplot(2,1,2);
    plot_confidence_intervals(10*log10(preHz),10*log10(Pre),[],'r');
        hold on
    plot_confidence_intervals(10*log10(postHz),10*log10(Post),[],'b');
        title('Plot from average PMTM in loglog');
        xlabel('Frequency (HZ) (10*log10)');
        ylabel('dB (10*log10)');
        legend('PreStim','PostStim')
    
    if SAVE_FIGURES
        saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\PMTM_Plots\PMTM_' ([num2str(iPeth)]) '\LFP' num2str(iPeth) '_' 'AverageTrials_Overlay' ],'png')
        close
    end
    
    figure (iPeth+300);
    plot_confidence_intervals(preHz,10*log10(Pre),[],'r');
        title(['PMTM for LFP Channel ' num2str(iPeth) ' in striatum at 7.3mm DV']);
        xlabel('Frequency (HZ)');
        ylabel('dB (10*log10)');
        legend('PreStim','PostStim')
        hold on
    plot_confidence_intervals(postHz,10*log10(Post),[],'b');
        title(['PMTM for LFP Channel ' num2str(iPeth) ' in striatum at 7.3mm DV']);
        xlabel('Frequency (HZ)');
        ylabel('dB (10*log10)');
        legend('PreStim','PostStim')    
    
    if SAVE_FIGURES
        saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\PMTM_Plots\PMTM_' ([num2str(iPeth)]) '\LFP' num2str(iPeth) '_' 'AverageTrials_Overlay_Single' ],'png')
        close
    end   
    %%run all trials on PMTM, except this time for the small freq window
    trials = size(seshfile.PETH_W.M);
    trials = trials(1);
    for bb = 1:trials
        trialnum = num2str(bb);
        
        %%Run PMTM function for pre- and post- stim,
        [prePower,preHz] = pmtm(seshfile.PETH_W.M(bb,PreS), [], sMinFreq:sSpaceFreq:sMaxFreq,sFreq);
        [postPower,postHz] = pmtm(seshfile.PETH_W.M(bb,PostS), [], sMinFreq:sSpaceFreq:sMaxFreq,sFreq);
        
        %%Store PMTM prePower out to average
        sAvgPre(bb,:) = prePower;
        
        %%Store PMTM postPower out to average
        sAvgPost(bb,:) = postPower;
        
    end
    
    %Average PMTM power outs
    sAvgPre = mean(sAvgPre);
    sAvgPost = mean(sAvgPost);
    
    %%Create the figure
    figure (iPeth+400);
    subplot(2,2,1);
    plot(preHz,10*log10(sAvgPre),'r');
    title('Plot from average pre stim PMTM');
    xlabel('Frequency (HZ)');
    ylabel('dB (10*log10)');
    
    subplot(2,2,3);
    plot(10*log10(preHz),10*log10(sAvgPre),'r');
    title('Plot from average pre stim PMTM');
    xlabel('Frequency (HZ) (10*log10)');
    ylabel('dB (10*log10)');
    
    subplot(2,2,2);
    plot(postHz,10*log10(sAvgPost),'b');
    title('Plot from average post stim PMTM');
    xlabel('Frequency (HZ)');
    ylabel('dB (10*log10)');
    
    subplot(2,2,4);
    plot(10*log10(postHz),10*log10(sAvgPost),'b');
    title('Plot from average post stim PMTM');
    xlabel('Frequency (HZ) (10*log10)');
    ylabel('dB (10*log10)');
    
    if SAVE_FIGURES
        saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\PMTM_Plots\PMTM_' ([num2str(iPeth)]) '\LFP' num2str(iPeth) '_' 'AverageTrials_SmWindow' ],'png')
        close
    end
    
    figure(iPeth+500);
    subplot(2,1,1);
    plot(preHz,10*log10(sAvgPre),'r');
    hold on
    plot(postHz,10*log10(sAvgPost),'b');
    title('Plot from average PMTM');
    xlabel('Frequency (HZ)');
    ylabel('dB (10*log10)');
    legend('PreStim','PostStim')
    subplot(2,1,2);
    plot(10*log10(preHz),10*log10(sAvgPre),'r');
    hold on
    plot(10*log10(postHz),10*log10(sAvgPost),'b');
    title('Plot from average PMTM in loglog');
    xlabel('Frequency (HZ) (10*log10)');
    ylabel('dB (10*log10)');
    legend('PreStim','PostStim')
    
    if SAVE_FIGURES
        saveas(gcf,['.\Validation_Figures\' num2str(SAVE_PATH) '\PMTM_Plots\PMTM_' ([num2str(iPeth)]) '\LFP' num2str(iPeth) '_' 'AverageTrials_SmWindow_Overlay' ],'png')
        close
    end
    
end
