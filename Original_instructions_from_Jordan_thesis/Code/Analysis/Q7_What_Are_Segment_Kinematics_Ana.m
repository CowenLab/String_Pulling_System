%Script to plot kinematics for both paws for each segment
%need to update to run on each day
fontSize=20;

paws={'Right' 'Left'};
phases={'Reach' 'Withdraw'};
segmentNames={ 'Lift' 'Advance' 'Grasp' 'Pull' 'Push'  'Reach' 'Withdraw'};
%measurements= {'movementSpeed' 'avgSpeed' 'peakSpeed'  'eucleadianDistance' 'totalDistance' 'movementTime' 'pathCircuitry' };
measurements= {'avgSpeed' 'peakSpeed'  'eucleadianDistance' 'totalDistance' 'movementTime' 'pathCircuitry' };

%load data here
%kinematics = Q7_What_Are_Segment_Kinematics();

analysis_directory='C:\Temp\TempAnaResults';
question='Q7_What_Are_Segment_Kinematics';
targetdir=fullfile(analysis_directory,question);
addpath(targetdir)

inputname=dir(fullfile(targetdir,'Dset*.mat'));
inputstruct={};



for i=1:length(inputname)
    xlabels{i}=inputname(i).name;
    xlabels{i}=xlabels{i}(14:15);
    inputstruct{i}=load( inputname(i).name);
    
end

%%

%iterate through sessions
for sess=1:length(inputname)
    
    %load data
    kinematics=inputstruct{sess};
    fprintf("Analyzing Rat %d Session %d",kinematics.SES.Rat,kinematics.SES.Session)
    
    %%
    %Distribution Viz
    for i=1:length(measurements)
        fig=figure
        %build histograms of distributions
        for j=1:length(segmentNames)
            
            
            
            subplot(7,2,(2*(j-1)+1))
            histogram(kinematics.Right.(segmentNames{j}).(measurements{i}))
            title(sprintf("Right Paw %s Segment",segmentNames{j}))
            ylabel("Count")
            
            subplot(7,2,(2*(j-1)+2))
            histogram(kinematics.Left.(segmentNames{j}).(measurements{i}))
            title(sprintf("Left Paw %s Segment",segmentNames{j}))
            ylabel("Count")
            
            
            
        end
        
        axes=findobj(fig,'Type','Axes');
        xlabhc=get(axes,'XLabel');
        xlabh=[xlabhc{:}];
        
        
        
        switch measurements{i}
            
            case 'movementSpeed'
                sgtitle(sprintf("Movement Speed Distributions"))
                
                set(xlabh,'String',"Speed (cm/s)");
            case 'peakSpeed'
                sgtitle(sprintf("Peak Speed Distributions"))
                
                set(xlabh,'String',"Speed (cm/s)");
            case 'avgSpeed'
                sgtitle(sprintf("Average Speed Distributions"))
               
                set(xlabh,'String',"Speed (cm/s)");
            case 'eucleadianDistance'
                sgtitle(sprintf("Displacement Distributions"))
                
                set(xlabh,'String',"Distance (cm)");
            case 'totalDistance'
                sgtitle(sprintf("Total Distance Distributions"))
                
                set(xlabh,'String',"Distance (cm)");
            case 'movementTime'
                sgtitle(sprintf("Elapsed Time Distributions"))
               
                set(xlabh,'String',"Time (s)");
            case 'pathCircuitry'
                sgtitle(sprintf("Path Circuitry Distributions"))
                
                set(xlabh,'String',"Path Circuitry");
        end
        
        set(gcf,'Position',get(0,'Screensize'));
        
    end
    %%
    
    %iterate thorugh each kinematic calculated
    for i=1:length(measurements)
        figure
        %iterate through each segment to make violin plot
        for j=1:length(segmentNames)
            clear display
            %makes 1 x 5 plot where each sub plot is a segment's values of the
            %given measurement
            subplot(1,7,j)
            
            %take out kinematics of interest
            rightMeasure=kinematics.Right.(segmentNames{j}).(measurements{i});
            leftMeasure=kinematics.Left.(segmentNames{j}).(measurements{i});
            
            %process for plots of differing lengths
            
            
            if endsWith(measurements{i},"Speed")
                %replace with better test for bimodal distributions
                P=ranksum(rightMeasure,leftMeasure);
            else
                P=ranksum(rightMeasure,leftMeasure);
            end
            
            if strcmp(measurements{i}, 'movementSpeed')
                
                display=table({rightMeasure,leftMeasure});
            else
                
                
                display=table({rightMeasure,leftMeasure});
                
            end

            
            
            %for Violin plots
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %Violin Func:
      %Holger Hoffmann (2021). Violin Plot (https://www.mathworks.com/matlabcentral/fileexchange/45134-violin-plot), MATLAB Central File Exchange. Retrieved February 17, 2021.
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
            
            [~,L,~,~,~]=violin(display{:,:},'xlabel',{'Right', 'Left'},'facecolor',[1 0 0;0 0 1],'plotlegend',1);
            
            if ~strcmp(segmentNames{j},'Pull')
               delete(L)
            end
            

            
            %titles
            if (j==1)
                switch measurements{i}
                    
                    case 'movementSpeed'
                        sgtitle("Movement Speed",'FontSize',fontSize+4)
                        ylabel("Speed (cm/s)")
                        
                    case 'peakSpeed'
                        sgtitle("Peak Speed",'FontSize',fontSize+4)
                        ylabel("Speed (cm/s)")
                        
                    case 'avgSpeed'
                        sgtitle("Average Speed",'FontSize',fontSize+4)
                        ylabel("Speed (cm/s)")
                        
                    case 'eucleadianDistance'
                        sgtitle("Displacement",'FontSize',fontSize+4)
                        ylabel("Distance (cm)")
                        
                    case 'totalDistance'
                        sgtitle("Total Distance",'FontSize',fontSize+4)
                        ylabel("Distance (cm)")
                        
                    case 'movementTime'
                        sgtitle("Elapsed Time",'FontSize',fontSize+4)
                        ylabel("Time (s)")
                        
                    case 'pathCircuitry'
                        sgtitle("Path Circuitry",'FontSize',fontSize+4)
                        ylabel("Time (s)")
                        
                        
                end
            end
            
            
            switch measurements{i}
                
                case 'movementSpeed'
                    
                    ylim([0 150])
                case 'peakSpeed'
                    
                    ylim([0 150])
                case 'avgSpeed'
                    
                    ylim([0 150])
                case 'eucleadianDistance'
                    
                    ylim([0 15])
                case 'totalDistance'
                    
                    ylim([0 15])
                case 'movementTime'
                    
                    ylim([0 0.6])
                case 'pathCircuitry'
                    
                    ylim([0 1])
                    
            end
            
            
            if strcmp(segmentNames{j}, 'Reach') | strcmp(segmentNames{j}, 'Withdraw')
                title(sprintf("%s Phase",segmentNames{j}),'FontSize',fontSize)
            else
                title(sprintf("%s Segment",segmentNames{j}),'FontSize',fontSize)
            end
                    yt=get(gca,'YTick');
                    axis([xlim 0 (max(yt)*1.15)])
                    xt=get(gca,'XTick');
                    if P<.05
                        hold on
                        plot(xt([1 2]), [1 1]*max(yt)*1.05, '-k', mean(xt([1 2])), max(yt)*1.1, '*k')
                        hold off
                    end
            
            
        end
        
        %changing font size breaks the violin plots
        % ax=gca;
        % ax.FontSize=fontSize;
        %
        set(gcf,'Position',get(0,'Screensize'));
        
        
    end
    
    
%     %%
%     %Detailed Speed Violin Plots
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     %Violin Func:
%     %Holger Hoffmann (2021). Violin Plot (https://www.mathworks.com/matlabcentral/fileexchange/45134-violin-plot), MATLAB Central File Exchange. Retrieved February 17, 2021.
%     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     
%     
%     
%     %     liftSpeedsR=kinematics.Right.Lift.movementSpeed;
%     %     advSpeedsR=kinematics.Right.Advance.movementSpeed;
%     %     liftSpeedsL=kinematics.Left.Lift.movementSpeed;
%     %     advSpeedsL=kinematics.Left.Advance.movementSpeed;
%     %
%     %
%     %     lift=table({liftSpeedsR, liftSpeedsL});
%     %     adv=table({advSpeedsR, advSpeedsL});
%     %
%     %
%     %     figure
%     %     violin(lift{:,:},'xlabel',{'Right Paw', 'Left Paw'})
%     %     title("Lift Paw Speeds")
%     %     ylabel("Speed (cm/s)")
%     %     set(gcf,'Position',get(0,'Screensize'));
%     %
%     %     figure
%     %     violin(adv{:,:},'xlabel',{'Right Paw', 'Left Paw'})
%     %     title("Advance Paw Speeds")
%     %     ylabel("Speed (cm/s)")
%     %     set(gcf,'Position',get(0,'Screensize'));
%     %
%     %% Clustering
%     %idx=kmeans(kinematics.Right.Pull{:,:},2);
%     idx=kmeans([kinematics.Right.Push.peakSpeed,kinematics.Right.Push.eucleadianDistance],2);
%     % int=idx==1;
%     % segments.Right.Withdraw=segments.Right.Withdraw(int,:);
%     x=[kinematics.Right.Push.peakSpeed,kinematics.Right.Push.eucleadianDistance];
%     figure
%     scatter(x(idx==1,1),x(idx==1,2),'b');hold on;scatter(x(idx==2,1),x(idx==2,2),'r');
%     
%     Y=tsne(kinematics.Right.Push{:,:});
%     figure
%     gscatter(Y(:,1),Y(:,2),idx(~isnan(kinematics.Right.Push.peakSpeed)),[0,0,1;1,0,0])
    
end

