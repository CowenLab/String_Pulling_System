function [OUT] = LK_Segment_Pulls_Further(varargin)
%LK_Segment_Pulls_Further
%   code to segment reach and withdraw phases of string pulling into 5
%   phases ID'd by Blackwell et. al 2018
% Outputs indexes of the start of each of 5 phases and end of
% reach/withdraw phases
% Has option to plot trajectories as well

%%
OUT = [];
GP = LK_Globals;
Behavior_sFreq = 100;
neuron_quality_threshold = 2;

% if length(varargin)>0
%     showPlots=cell2mat(varargin(1));
%     combinePlots=cell2mat(varargin(2));
% else
%     showPlots = false;
%     combinePlots=false;
% end
showPlots=true;
combinePlots=true;

load('EVT.mat')
if ~isempty(EVT.front_camera_frame_ID) && ~isempty(EVT.rotary_encoder_ID)
    fprintf("Detected Neural Recording Session")
    ePhys=1;
else
    fprintf("Detected Behavior Session")
    ePhys=0;
end
clear EVT


reachPhases={'Lift' 'Advance' 'Grasp' 'End'};
withdrawPhases={'Pull' 'Push' 'End'};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SES = LK_Session_Info();
OUT.SES = SES;



if ePhys
[MT, string_pull_intervals_uSec,PAW,~,~,~,EVENTS] = LK_Combine_All_String_Pull_Motion_To_Table(Behavior_sFreq, false);
epoch_st_ed_uSec = [string_pull_intervals_uSec(1) - 2e6 string_pull_intervals_uSec(end) + 2e6 ]; % add a little padding.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load spikes and restrict to the times of interest.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[SP,TS_uS] = LK_Load_Spikes(neuron_quality_threshold,epoch_st_ed_uSec);
else
load('Filtered_Time_Stamped_Coordinates_Corrected_Ori.mat')
load('good_string_pull_intervals_uSec.mat');
[PAW, EVENTS] = LK_process_paw_data(T3, good_string_pull_intervals_uSec);
end

%load('Filtered_Time_Stamped_Coordinates_Corrected_Ori');


%[PAW,~]=LK_process_paw_data(T3,good_string_pull_intervals_uSec);


eventNames=fieldnames(EVENTS);

%convert event from uS to frame index
for i=1:length(eventNames)
    for j=1:length(EVENTS.(eventNames{i}))
        
        idx.(eventNames{i})(j)=find(PAW.Time_uSec==EVENTS.(eventNames{i})(j),1);
        
    end
end

%%
figure
rightReach=NaN(length(EVENTS.Right_start_up_t_uS),4);

%for Right Paw Lift/Advance
for i=1:1:length(EVENTS.Right_start_up_t_uS)
    
    %Find where x derivative changes signs, take max/min x value as peak
    I=nan;
    x=diff(PAW.Right_x(idx.Right_start_up_t_uS(i):idx.Right_end_up_t_uS(i)));
    x2=x<0;
    chg=sort([strfind(x2'>0, [0 1]) strfind(x2'>0, [1 0])]);
    [~,I]=min(PAW.Right_x(chg+idx.Right_start_up_t_uS(i)));
    adv=chg(I)+idx.Right_start_up_t_uS(i);
    if isempty(adv)
        adv=nan;
    end
    
    %take y derivative, compute average and standard deviation
    %define grasp start as first point where y derivative is more than .5
    %std dev less than mean
    
    y=diff(PAW.Right_y(idx.Right_start_up_t_uS(i):idx.Right_end_up_t_uS(i)));
    
    avg=mean(y);
    sd=std(y);
%     if isnan(adv)
        grp=strfind(y(chg(I):end)'<(avg-(sd/2)), [0 1]);
%     else
%         grp=strfind(y(adv-idx.Right_start_up_t_uS(i):end)'<(avg-(sd/2)), [0 1]);
%     end
    
    if ~isempty(grp)
        grp=grp(end)+idx.Right_start_up_t_uS(i)+chg(I);
    else
        grp=nan;
    end
    
    
    %log phase start indexes to array
    rightReach(i,:)=[idx.Right_start_up_t_uS(i) adv grp idx.Right_end_up_t_uS(i)];
    
    %display
    if showPlots
        switch combinePlots
            case 0
                figure
                plot(PAW.Right_x(idx.Right_start_up_t_uS(i):idx.Right_end_up_t_uS(i)),PAW.Right_y(idx.Right_start_up_t_uS(i):idx.Right_end_up_t_uS(i)),'.','markersize',1,'color',[.4 .4 .4])
                hold on
                if ~isnan(adv)
                    scatter(PAW.Right_x(adv),PAW.Right_y(adv),'r')
                    hold on
                end
                if ~isnan(grp)
                    scatter(PAW.Right_x(grp),PAW.Right_y(grp),'g')
                end
                hold off
                
                
                
            case 1
                
                subplot(2,2,1)
                title('Right Paw Reach Segments - Lift, Advance, Grasp')
                %                 plot(PAW.Right_x(idx.Right_start_up_t_uS(i):idx.Right_end_up_t_uS(i))-PAW.Right_x(idx.Right_start_up_t_uS(i)),PAW.Right_y(idx.Right_start_up_t_uS(i):idx.Right_end_up_t_uS(i))-PAW.Right_y(idx.Right_start_up_t_uS(i)),'.','markersize',1,'color',[.4 .4 .4])
                %                 hold on
                %                 if ~isnan(adv)
                %                 scatter(PAW.Right_x(adv)-PAW.Right_x(idx.Right_start_up_t_uS(i)),PAW.Right_y(adv)-PAW.Right_y(idx.Right_start_up_t_uS(i)),'r')
                %                 hold on
                %                 end
                %                 if ~isnan(grp)
                %                 scatter(PAW.Right_x(grp)-PAW.Right_x(idx.Right_start_up_t_uS(i)),PAW.Right_y(grp)-PAW.Right_y(idx.Right_start_up_t_uS(i)),'g')
                %                 hold on
                %                 %end
                
                
                if ~isnan(adv) && ~isnan(grp)
                    
                    
                    plot(PAW.Right_x(idx.Right_start_up_t_uS(i):adv)-PAW.Right_x(idx.Right_start_up_t_uS(i)),PAW.Right_y(idx.Right_start_up_t_uS(i):adv)-PAW.Right_y(idx.Right_start_up_t_uS(i)),'markersize',1,'color',[1 0 0])
                    plot(PAW.Right_x(adv:grp)-PAW.Right_x(idx.Right_start_up_t_uS(i)),PAW.Right_y(adv:grp)-PAW.Right_y(idx.Right_start_up_t_uS(i)),'markersize',1,'color',[0 1 0])
                    plot(PAW.Right_x(grp:idx.Right_end_up_t_uS(i))-PAW.Right_x(idx.Right_start_up_t_uS(i)),PAW.Right_y(grp:idx.Right_end_up_t_uS(i))-PAW.Right_y(idx.Right_start_up_t_uS(i)),'markersize',1,'color',[0 0 1])
                    hold on
                end
                
        end
        
        
    end
end
hold off
rightReach=array2table(rightReach);
rightReach.Properties.VariableNames=reachPhases;

%%
rightWithdraw=NaN(length(EVENTS.Right_start_down_t_uS),3);
%for Right Paw Pull/Push
for i=1:1:length(EVENTS.Right_start_down_t_uS)
    %Find where x derivative changes signs, take max/min as peak in that
    %direction
    x=diff(PAW.Right_x(idx.Right_start_down_t_uS(i):idx.Right_end_down_t_uS(i)));
    x2=x<0;
    chg=sort([strfind(x2'>0, [0 1]) strfind(x2'>0, [1 0])]);
    [~,I]=max(PAW.Right_x(chg+idx.Right_start_down_t_uS(i)));
    
    if ~isempty(I)
        psh=chg(I)+idx.Right_start_down_t_uS(i);
    else
        psh=nan;
    end
    
    
    %log start indexes to array
    rightWithdraw(i,:)=[idx.Right_start_down_t_uS(i)    psh     idx.Right_end_down_t_uS(i)];
    
    %display
    if showPlots
        switch combinePlots
            case 0
                figure
                plot(PAW.Right_x(idx.Right_start_down_t_uS(i):idx.Right_end_down_t_uS(i)),PAW.Right_y(idx.Right_start_down_t_uS(i):idx.Right_end_down_t_uS(i)),'.','markersize',1,'color',[.4 .4 .4])
                hold on
                if ~isnan(psh)
                    scatter(PAW.Right_x(psh),PAW.Right_y(psh),'b')
                end
                hold off
            case 1
               subplot(2,2,3)
                title('Right Paw Withdraw Segments - Pull, Push')
                %                 plot(PAW.Right_x(idx.Right_start_down_t_uS(i):idx.Right_end_down_t_uS(i))-PAW.Right_x(idx.Right_start_down_t_uS(i)),PAW.Right_y(idx.Right_start_down_t_uS(i):idx.Right_end_down_t_uS(i))-PAW.Right_y(idx.Right_start_down_t_uS(i)),'.','markersize',1,'color',[.4 .4 .4])
                %                 hold on
                %                 if ~isnan(psh)
                %                 scatter(PAW.Right_x(psh)-PAW.Right_x(idx.Right_start_down_t_uS(i)),PAW.Right_y(psh)-PAW.Right_y(idx.Right_start_down_t_uS(i)),'b')
                %                 hold on
                %                 end
                
                if ~isnan(psh)
                    
                    
                    plot(PAW.Right_x(idx.Right_start_down_t_uS(i):psh)-PAW.Right_x(idx.Right_start_down_t_uS(i)),PAW.Right_y(idx.Right_start_down_t_uS(i):psh)-PAW.Right_y(idx.Right_start_down_t_uS(i)),'markersize',1,'color',[1 0 0])
                    plot(PAW.Right_x(psh:idx.Right_end_down_t_uS(i))-PAW.Right_x(idx.Right_start_down_t_uS(i)),PAW.Right_y(psh:idx.Right_end_down_t_uS(i))-PAW.Right_y(idx.Right_start_down_t_uS(i)),'markersize',1,'color',[0 0 1])
                    hold on
                end
                
                
        end
    end
end
hold off
rightWithdraw=array2table(rightWithdraw);
rightWithdraw.Properties.VariableNames=withdrawPhases;

%%

leftReach=NaN(length(EVENTS.Left_start_up_t_uS),4);
%for Left Paw Lift/Advance, same structre as right paw
for i=1:1:length(EVENTS.Left_start_up_t_uS)
    x=diff(PAW.Left_x(idx.Left_start_up_t_uS(i):idx.Left_end_up_t_uS(i)));
    x2=x<0;
    chg=sort([strfind(x2'>0, [0 1]) strfind(x2'>0, [1 0])]);
    [~,I]=max(PAW.Left_x(chg+idx.Left_start_up_t_uS(i)));
    adv=chg(I)+idx.Left_start_up_t_uS(i);
    if isempty(adv)
        adv=nan;
    end
    
%     if isnan(adv)
    y=diff(PAW.Left_y(idx.Left_start_up_t_uS(i):idx.Left_end_up_t_uS(i)));
%     else
%     y=diff(PAW.Left_y(adv:idx.Left_end_up_t_uS(i)));
%     end
    avg=mean(y);
    sd=std(y);
%     if isnan(adv)
        grp=strfind(y(chg(I):end)'<(avg-(sd/2)), [0 1]);
%     else
%         grp=strfind(y(adv-idx.Left_start_up_t_uS(i):end)'<(avg-(sd/2)), [0 1]);
%     end
    
    if ~isempty(grp)
        grp=grp(end)+idx.Left_start_up_t_uS(i)+chg(I);
    else
        grp=nan;
    end
    
    
    leftReach(i,:)=[idx.Left_start_up_t_uS(i) adv grp idx.Left_end_up_t_uS(i)];
    if showPlots
        switch combinePlots
            case 0
                figure
                plot(PAW.Left_x(idx.Left_start_up_t_uS(i):idx.Left_end_up_t_uS(i)),PAW.Left_y(idx.Left_start_up_t_uS(i):idx.Left_end_up_t_uS(i)),'.','markersize',1,'color',[.4 .4 .4])
                hold on
                if ~isnan(adv)
                    scatter(PAW.Left_x(adv),PAW.Left_y(adv),'r')
                    hold on
                end
                if ~isnan(grp)
                    scatter(PAW.Left_x(grp),PAW.Left_y(grp),'g')
                end
                hold off
            case 1
                subplot(2,2,2)
                title('Left Paw Reach Segments')
                
                %                 plot(PAW.Left_x(idx.Left_start_up_t_uS(i):idx.Left_end_up_t_uS(i))-PAW.Left_x(idx.Left_start_up_t_uS(i)),PAW.Left_y(idx.Left_start_up_t_uS(i):idx.Left_end_up_t_uS(i))-PAW.Left_y(idx.Left_start_up_t_uS(i)),'.','markersize',1,'color',[.4 .4 .4])
                %                 hold on
                %                 if ~isnan(adv)
                %                 scatter(PAW.Left_x(adv)-PAW.Left_x(idx.Left_start_up_t_uS(i)),PAW.Left_y(adv)-PAW.Left_y(idx.Left_start_up_t_uS(i)),'r')
                %                 hold on
                %                 end
                %                 if ~isnan(grp)
                %                 scatter(PAW.Left_x(grp)-PAW.Left_x(idx.Left_start_up_t_uS(i)),PAW.Left_y(grp)-PAW.Left_y(idx.Left_start_up_t_uS(i)),'g')
                %                 end
                
                
                if ~isnan(adv) && ~isnan(grp)
                    
                    
                    plot(PAW.Left_x(idx.Left_start_up_t_uS(i):adv)-PAW.Left_x(idx.Left_start_up_t_uS(i)),PAW.Left_y(idx.Left_start_up_t_uS(i):adv)-PAW.Left_y(idx.Left_start_up_t_uS(i)),'markersize',1,'color',[1 0 0])
                    plot(PAW.Left_x(adv:grp)-PAW.Left_x(idx.Left_start_up_t_uS(i)),PAW.Left_y(adv:grp)-PAW.Left_y(idx.Left_start_up_t_uS(i)),'markersize',1,'color',[0 1 0])
                    plot(PAW.Left_x(grp:idx.Left_end_up_t_uS(i))-PAW.Left_x(idx.Left_start_up_t_uS(i)),PAW.Left_y(grp:idx.Left_end_up_t_uS(i))-PAW.Left_y(idx.Left_start_up_t_uS(i)),'markersize',1,'color',[0 0 1])
                    hold on
                end
                
        end
        
    end
end
legend({'grasp' 'advance' 'lift'})
hold off
leftReach=array2table(leftReach);
leftReach.Properties.VariableNames=reachPhases;
%%
leftWithdraw=NaN(length(EVENTS.Left_start_down_t_uS),3);
%for Left Paw Pull/Push, same structre as right paw
for i=1:1:length(EVENTS.Left_start_down_t_uS)
    x=diff(PAW.Left_x(idx.Left_start_down_t_uS(i):idx.Left_end_down_t_uS(i)));
    x2=x<0;
    chg=sort([strfind(x2'>0, [0 1]) strfind(x2'>0, [1 0])]);
    [~,I]=min(PAW.Left_x(chg+idx.Left_start_down_t_uS(i)));
    psh=chg(I)+idx.Left_start_down_t_uS(i);
    
    if ~isempty(I)
        psh=chg(I)+idx.Left_start_down_t_uS(i);
    else
        psh=nan;
    end
    
    
    leftWithdraw(i,:)=[idx.Left_start_down_t_uS(i)    psh     idx.Left_end_down_t_uS(i)];
    
    if showPlots
        switch combinePlots
            case 0
                figure
                plot(PAW.Left_x(idx.Left_start_down_t_uS(i):idx.Left_end_down_t_uS(i)),PAW.Left_y(idx.Left_start_down_t_uS(i):idx.Left_end_down_t_uS(i)),'.','markersize',1,'color',[.4 .4 .4])
                hold on
                if ~isnan(psh)
                    scatter(PAW.Left_x(psh),PAW.Left_y(psh),'b')
                end
                hold off
            case 1
                subplot(2,2,4)
                title('Left Paw Withdraw Segments')
                %                                 plot(PAW.Left_x(idx.Left_start_down_t_uS(i):idx.Left_end_down_t_uS(i))-PAW.Left_x(idx.Left_start_down_t_uS(i)),PAW.Left_y(idx.Left_start_down_t_uS(i):idx.Left_end_down_t_uS(i))-PAW.Left_y(idx.Left_start_down_t_uS(i)),'.','markersize',1,'color',[.4 .4 .4])
                %                                 hold on
                %                                 if ~isnan(psh)
                %                                 scatter(PAW.Left_x(psh)-PAW.Left_x(idx.Left_start_down_t_uS(i)),PAW.Left_y(psh)-PAW.Left_y(idx.Left_start_down_t_uS(i)),'b')
                %                                 end
                %                                 hold on
                
                
                
                if ~isnan(psh)
                    plot(PAW.Left_x(idx.Left_start_down_t_uS(i):psh)-PAW.Left_x(idx.Left_start_down_t_uS(i)),PAW.Left_y(idx.Left_start_down_t_uS(i):psh)-PAW.Left_y(idx.Left_start_down_t_uS(i)),'markersize',1,'color',[1 0 0])
                    plot(PAW.Left_x(psh:idx.Left_end_down_t_uS(i))-PAW.Left_x(idx.Left_start_down_t_uS(i)),PAW.Left_y(psh:idx.Left_end_down_t_uS(i))-PAW.Left_y(idx.Left_start_down_t_uS(i)),'markersize',1,'color',[0 0 1])
                    hold on
                end
        end
    end
    
    
    
end
legend({'push' 'pull' })
hold off
leftWithdraw=array2table(leftWithdraw);
leftWithdraw.Properties.VariableNames=withdrawPhases;
%%
OUT.Right.Reach=rightReach;
OUT.Right.Withdraw=rightWithdraw;
OUT.Left.Reach=leftReach;
OUT.Left.Withdraw=leftWithdraw;



end
