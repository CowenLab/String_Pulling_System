%path to where outputs of Q6 are sotred
analysis_directory='C:\Temp\TempAnaResults';
question='Q6_When_Do_Neurons_Fire_After_Events';
targetdir=fullfile(analysis_directory,question);
addpath(targetdir)
fontSize=22;

%import data
inputname=dir(fullfile(targetdir,'Dset*.mat'));
inputstruct={};
sessions=[];
neuronNo=[];
selectiveR=logical([]);
rPrefPhase=[];
selectiveL=logical([]);
lPrefPhase=[];
totalN=0;
selectiveN=0;

for i=1:length(inputname)
    xlabels{i}=inputname(i).name;
    xlabels{i}=xlabels{i}(14:15);
    inputstruct{i}=load( inputname(i).name);
    
end


%iterate through sessions
for sess=1:length(inputname)
    fireRate=inputstruct{sess};    
    
    totalN=totalN+fireRate.nNeurons;
    %iterate through neurons
    for neuron=1:fireRate.nNeurons
        clear prefR prefL
        rH=false;
        lH=false;
        
        %load appropriate neurons firing rate
        right.Reach=fireRate.Right.Reach{:,neuron};
        right.Withdraw=fireRate.Right.Withdraw{:,neuron};
        
        left.Reach=fireRate.Left.Reach{:,neuron};
        left.Withdraw=fireRate.Left.Withdraw{:,neuron};
        
        %test for significant differences between reach and withdraw
        if ((sum(~isnan(right.Reach))>0) && (sum(~isnan(right.Withdraw))>0))
            [rP,rH]=ranksum(right.Reach,right.Withdraw);
            
            if ((rH) && (mean(right.Reach,'omitnan') > mean(right.Withdraw,'omitnan')))
                prefR='R';
            elseif ((rH) && (mean(right.Reach,'omitnan') < mean(right.Withdraw,'omitnan')))
                prefR='W';
            end
            
        end
        
        %test for significant differences between reach and withdraw
        if ((sum(~isnan(left.Reach))>0) && (sum(~isnan(left.Withdraw))>0))
            [lP,lH]=ranksum(left.Reach,left.Withdraw);
            
            if ((lH) && (mean(left.Reach,'omitnan') > mean(left.Withdraw,'omitnan')))
                prefL='R';
            elseif ((lH) && (mean(left.Reach,'omitnan') < mean(left.Withdraw,'omitnan')))
                prefL='W';
            end
            
        end
        
        %add neuron and preferred phase for final table
        if (rH & lH)
            sessions=[sessions;str2double(xlabels{sess}(:))];
            neuronNo=[neuronNo;neuron];
            selectiveR=[selectiveR;true];
            rPrefPhase=[rPrefPhase;prefR];
            selectiveL=[selectiveL;true];
            lPrefPhase=[lPrefPhase;prefL];
        elseif rH
            sessions=[sessions;str2double(xlabels{sess}(:))];
            neuronNo=[neuronNo;neuron];
            selectiveR=[selectiveR;true];
            selectiveL=[selectiveL;false];
            rPrefPhase=[rPrefPhase;prefR];
            lPrefPhase=[lPrefPhase;'/'];
        elseif lH
            sessions=[sessions;str2double(xlabels{sess}(:))];
            neuronNo=[neuronNo;neuron];
            selectiveL=[selectiveL;true];
            selectiveR=[selectiveR;false];
            lPrefPhase=[lPrefPhase;prefL];
            rPrefPhase=[rPrefPhase;'/'];
        end
        
        
        
    end
    


    
    
end

%build table with data of preferences
OUT=table(sessions,neuronNo,selectiveR,rPrefPhase,selectiveL,lPrefPhase);

%display
figure
subplot(2,2,1)
perSelR(1)=sum(OUT.rPrefPhase=='R')/totalN;
pie([perSelR(1), 1-perSelR(1)])
title("Neurons Selective to Right Paw Reach",'FontSize',fontSize+4)
pubify_figure_axis
ax=gca;
ax.FontSize=fontSize;


subplot(2,2,2)
perSelR(2)=sum(OUT.rPrefPhase=='W')/totalN;
pie([perSelR(2), 1-perSelR(2)])
title("Neurons Selective to Right Withdraw",'FontSize',fontSize+4)
pubify_figure_axis
ax=gca;
ax.FontSize=fontSize;

subplot(2,2,3)
perSelL(1)=sum(OUT.lPrefPhase=='R')/totalN;
pie([perSelL(1), 1-perSelL(1)])
title("Neurons Selective to Left Paw Reach",'FontSize',fontSize+4)
pubify_figure_axis
ax=gca;
ax.FontSize=fontSize;

subplot(2,2,4)
perSelL(2)=sum(OUT.lPrefPhase=='W')/totalN;
pie([perSelL(2), 1-perSelL(2)])
title("Neurons Selective to Left Withdraw",'FontSize',fontSize+4)
legend({'Selective' 'Not Selective'},'Location','Southwest')
pubify_figure_axis
ax=gca;
ax.FontSize=fontSize;

set(gcf,'Position',get(0,'Screensize'))


figure
bar([perSelR(1),perSelL(1);perSelR(2),perSelL(2)],'stacked')
legend({'Reach','Withdraw'})
xticklabels({'Right Paw','Left Paw'})
ylabel("Percent")
title("Proportion of Neurons Selective to Phase",'FontSize',fontSize)
ax=gca;
ax.FontSize=fontSize;
set(gcf,'Position',get(0,'Screensize'))
ax.YTickLabels=[{'0'}     {'5'}    {'10' }    {'15'}    {'20' }    {'25'}    {'30' }    {'35'}    {'40' }];

