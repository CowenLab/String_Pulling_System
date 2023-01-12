function [fireRate] = Q6_When_Do_Neurons_Fire_After_Events()
%Q6_WHEN_DO_NEURONS_FIRE Summary of this function goes here
%   Function generates graphs of neuron firings for reaches/withdraws and
%   PETHS for starts of each segment
%   Don't try to generate all figures at once or matlab will crash 
%   Code is sectioned to generate firing locations for Right Paw, Left Paw,
%   and PETHS so just do one at a time

%%
OUT = [];
GP = LK_Globals;
PLOT_IT = true;
Behavior_sFreq = 367;
neuron_quality_threshold = 2;

%for PETHs
PETH_win_ms = 500;
binSize=50;

show='off';




PXmap   =  [386,386,387];
pxPerCm=median(PXmap)/10;

paws={'Right' 'Left'};
phases={'Reach' 'Withdraw'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SES = LK_Session_Info();
OUT.SES = SES;
OUT.neuron_quality_threshold = neuron_quality_threshold;


[MT, string_pull_intervals_uSec,~,~,~,~,EVENTS] = LK_Combine_All_String_Pull_Motion_To_Table(Behavior_sFreq, false);
epoch_st_ed_uSec = [string_pull_intervals_uSec(1) - 2e6 string_pull_intervals_uSec(end) + 2e6 ]; % add a little padding.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load spikes and restrict to the times of interest.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[SP,TS_uS] = LK_Load_Spikes(neuron_quality_threshold,epoch_st_ed_uSec);
OUT.n_neurons = length(SP);




load('Filtered_Time_Stamped_Coordinates_Corrected_Ori');
load('good_string_pull_intervals_uSec.mat');

[PAW,~]=LK_process_paw_data(T3,good_string_pull_intervals_uSec);

%Save paw/nose positions at neuron firing times
for i=1:length(TS_uS)
    N(i).xy=array2table(interp1(PAW.Time_uSec,table2array(PAW),SP(i).t_uS));
    
    N(i).xy.Properties.VariableNames=PAW.Properties.VariableNames;
end



%Events are given in times, find corresponding frame index for each given
%timestamp
eventNames=fieldnames(EVENTS);

for i=1:length(eventNames)
    for j=1:length(EVENTS.(eventNames{i}))
        
        idx.(eventNames{i})(j)=find(PAW.Time_uSec==EVENTS.(eventNames{i})(j),1);
        
    end
end

fireRate.nNeurons=length(SP);
%% Right Paw Pulls




%iterate over reaches and withdraws
for j=1:2:4%length(eventNames)
    fR=zeros(length(idx.(eventNames{j})),length(SP));
    %create figure with each identified trace stacked
    for k=1:length(idx.(eventNames{j}))
        
        %iterate over neurons
        for i=1:length(SP)
            
            if strcmp(show,'on')
            figure('visible',show)
            set(gcf, 'WindowState', 'maximized');
            end
            
            %start and end indices
            PSidx=idx.(eventNames{j})(k);
            PEidx=idx.(eventNames{j+1})(k);
            
            %just look at neuron firing locations withing region of interest
            NRight_x=Restrict([SP(i).t_uS N(i).xy.Right_x],EVENTS.(eventNames{j})(k),EVENTS.(eventNames{j+1})(k));
            NRight_y=Restrict([SP(i).t_uS N(i).xy.Right_y],EVENTS.(eventNames{j})(k),EVENTS.(eventNames{j+1})(k));
            
            if ~isempty(NRight_x)
                fR(k,i)=(length(NRight_x)/((PAW.Time_uSec(PEidx)-PAW.Time_uSec(PSidx))/(1e6)));
            end
            %plots paw trajectories
            
            if strcmp(show,'on')
            plot(PAW.Right_x(PSidx:PEidx)-PAW.Right_x(PSidx),PAW.Right_y(PSidx:PEidx)-PAW.Right_y(PSidx),'.','markersize',1,'color',[.4 .4 .4]);
            xlim([-300 300])
            axis xy
            
            
            switch eventNames{j}
                case 'Right_start_up_t_uS'
                    subplot(1,2,1)
                    title(sprintf("Right Paw Reaches and Neuron %d Firings",i))
                    ylim([0 600])
                case 'Right_start_down_t_uS'
                    subplot(1,2,2)
                    title(sprintf("Right Paw Withdraws and Neuron %d Firings",i))
                    ylim([-600 0])
                    
                    
            end
            
            hold on;
            %overlays neuron firing locations in blue dots
            plot(NRight_x-PAW.Right_x(PSidx),NRight_y-PAW.Right_y(PSidx),'o','markersize',7,'MarkerFaceColor',[0 0 1],'MarkerEdgeColor',[0 0 1])
            end
        end
        
    end
    
    fireRate.Right.(phases{floor((j/2))+1})=array2table(fR);
    hold off
end
%% Left Paw Pulls
%structure same as right paw

for j=5:2:7%length(eventNames)
    fR=zeros(length(idx.(eventNames{j})),length(SP));
    
    for k=1:1:length(idx.(eventNames{j}))
        
        for i=1:length(SP)
            
            if strcmp(show,'on')
            figure('visible',show)
            set(gcf, 'WindowState', 'maximized');
            end
            
            PSidx=idx.(eventNames{j})(k);
            PEidx=idx.(eventNames{j+1})(k);
            
            
            NLeft_x=Restrict([SP(i).t_uS N(i).xy.Left_x],EVENTS.(eventNames{j})(k),EVENTS.(eventNames{j+1})(k));
            NLeft_y=Restrict([SP(i).t_uS N(i).xy.Left_y],EVENTS.(eventNames{j})(k),EVENTS.(eventNames{j+1})(k));
            
            if ~isempty(NLeft_x)
                fR(k,i)=(length(NLeft_x)/((PAW.Time_uSec(PEidx)-PAW.Time_uSec(PSidx))/(1e6)));
            end
            
            if strcmp(show,'on')
            plot(PAW.Left_x(PSidx:3:PEidx)-PAW.Left_x(PSidx),PAW.Left_y(PSidx:3:PEidx)-PAW.Left_y(PSidx),'.','markersize',1,'color',[.4 .4 .4]);
            
            xlim([-300 300])
            switch eventNames{j}
                case 'Left_start_up_t_uS'
                    subplot(1,2,1)
                    title(sprintf("Left Paw Reaches Neuron %d Firings",i))
                    ylim([0 600])
                case 'Left_start_down_t_uS'
                    subplot(1,2,2)
                    title(sprintf("Left Paw Withdraws and Neuron %d Firings",i))
                    ylim([-600 0])
                    
                    
            end
            
            hold on;
            plot(NLeft_x-PAW.Left_x(PSidx),NLeft_y-PAW.Left_y(PSidx),'o','markersize',7,'MarkerFaceColor',[0 0 1],'MarkerEdgeColor',[0 0 1])
            end
            
        end
        
        
    end
    fireRate.Left.(phases{floor(((j-4)/2))+1})=array2table(fR);
    hold off
end
%%
%get segment start/end indices
segments=LK_Segment_Pulls_Further();
close

%%
%iterate through paws
for i=1:2
    %iterate through phases
    for j=1:2
        %iterate through segments until end of phase
        for col=1:width(segments.(paws{i}).(phases{j}))
            
            %get all indices of the starts of the current segment and
            %convert to timestamps
            segIdx=segments.(paws{i}).(phases{j}){:,col};
            segTimes=T3{segIdx(~isnan(segIdx)),8};
            
            for neuron=1:length(TS_uS)
                
                %find better way to store M, x, and A data
                [M{neuron},x,A]=PETH_raster(TS_uS{neuron}./100,segTimes./100,binSize,PETH_win_ms,PETH_win_ms);
                if strcmp(show,'on')
                figure('visible',show)
                plot_PETH(M{neuron},x,'trial_spike_times',A,'raster_type','dots','marker_size',5)
                title(sprintf("Neuron %d Activity Around Start of %s Paw %s",neuron,(paws{i}),segments.(paws{i}).(phases{j}).Properties.VariableNames{col}))
                pubify_figure_axis
                clear x
                clear A
                end
                %plot_confidence_intervals()
            end
        end
    end
end

%%
%Neuron PETHs over each phase


%it thorugh neurons
for neuron=1:length(TS_uS)
    %it thorugh paws
    for i=1:2
        if strcmp(show,'on')
        figure('visible',show)
        set(gcf,'Position',get(0,'Screensize'));
        sgtitle(sprintf("Neuron %d Activity for %s Paw Motion",neuron,paws{i}))
        subplot(5,1,1)
        
        %calculate segment start indices + times
        segIdx=segments.(paws{i}).Reach{:,1};
        segTimes=T3{segIdx(~isnan(segIdx)),8};
        
        
        %calc PETH data and plot for figure for each neuron, subplots are
        %each segment centered at segment start time
        [M{neuron},x,A]=PETH_raster(TS_uS{neuron}./100,segTimes./100,binSize,PETH_win_ms,PETH_win_ms);
        plot_confidence_intervals(x,M{neuron})
        title(sprintf("Lift Segment"))
        
        
        subplot(5,1,2)
        segIdx=segments.(paws{i}).Reach{:,2};
        segTimes=T3{segIdx(~isnan(segIdx)),8};
        
        [M{neuron},x,A]=PETH_raster(TS_uS{neuron}./100,segTimes./100,binSize,PETH_win_ms,PETH_win_ms);
        plot_confidence_intervals(x,M{neuron})
        title(sprintf("Advance Segment"))
        
        
        
        subplot(5,1,3)
        segIdx=segments.(paws{i}).Reach{:,3};
        segTimes=T3{segIdx(~isnan(segIdx)),8};
        
        [M{neuron},x,A]=PETH_raster(TS_uS{neuron}./100,segTimes./100,binSize,PETH_win_ms,PETH_win_ms);
        plot_confidence_intervals(x,M{neuron})
        title(sprintf("Grasp Segment"))
        
        
        subplot(5,1,4)
        segIdx=segments.(paws{i}).Withdraw{:,1};
        segTimes=T3{segIdx(~isnan(segIdx)),8};
        
        [M{neuron},x,A]=PETH_raster(TS_uS{neuron}./100,segTimes./100,binSize,PETH_win_ms,PETH_win_ms);
        plot_confidence_intervals(x,M{neuron})
        title(sprintf("Push Segment"))
        
        
        subplot(5,1,5)
        segIdx=segments.(paws{i}).Withdraw{:,2};
        segTimes=T3{segIdx(~isnan(segIdx)),8};
        
        [M{neuron},x,A]=PETH_raster(TS_uS{neuron}./100,segTimes./100,binSize,PETH_win_ms,PETH_win_ms);
        plot_confidence_intervals(x,M{neuron})
        title(sprintf("Pull Segment"))
        end
    end
    
    
end











end

