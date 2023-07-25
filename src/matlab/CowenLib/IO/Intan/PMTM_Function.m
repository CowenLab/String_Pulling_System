cd .\Validation_Figures
if ~exist('PMTM_Plots','dir')
        mkdir 'PMTM_Plots';
end
cd ..\

PreS = ix < 0;
PostS = ix > 500; 
%S = ix >= 0 & =< 500;

count = 1;
SAVE_FIGURES = true;

for ii =1:length(eeg_samples)
    
    [Power,Hz] = pmtm(M(ii,PreS), [], 0:2:400,sFreq);
    
    figure (count + 400);
    subplot(2,2,1);
        plot(Hz,10*log10(Power),'r');
        title('Plot from PMTM --figure out how to get Trial here');
        xlabel('Frequency (HZ)');
        ylabel('dB (10*log10)');

     subplot(2,2,3);
        plot(10*log10(Hz),10*log10(Power),'r');
        title('Plot from PMTM --figure out how to get Trial here');
        xlabel('Frequency (HZ) (10*log10)');
        ylabel('dB (10*log10)');
        
    [Power,Hz] = pmtm(M(ii,PostS), [], 0:2:400,sFreq);
   
    subplot(2,2,2);
        plot(Hz,10*log10(Power),'b');
        title('Plot from PMTM --figure out how to get trial here');
        xlabel('Frequency (HZ)');
        ylabel('dB (10*log10)');

     subplot(2,2,4);
        plot(10*log10(Hz),10*log10(Power),'b');
        title('Plot from PMTM --figure out how to get Trial here');
        xlabel('Frequency (HZ) (10*log10)');
        ylabel('dB (10*log10)');
        
    count = count+1;
    
     if SAVE_FIGURES
                saveas(gcf,['.\Validation_Figures\PMTM_Plots\PMTM_' num2str(count)],'png')
                close
     end
end