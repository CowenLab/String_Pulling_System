function OUT = Q5_Where_Do_Neurons_Fire()
%Q5_WHERE_DO_NEURONS_FIRE
%Produces heat maps of neuron firing for extremity positions
%   
% INPUTS
% OUTPUTS
%     OUT.Data: spike positions for paws and nose, number of firings per bin, fireRate in each bin
%     OUT.Edges.x: edges of x bins
%     OUT.Edges.y: edges of y bins
%%
OUT = [];
GP = LK_Globals;
PLOT_IT = true;
Behavior_sFreq = 367;
neuron_quality_threshold = 2;

%partitions in x and y directiosn for raw paw loc and paw loc in refrence
%to nose
Xpart=0:12*2:600;
Ypart=0:16*2:880;
XpartN=-300:12*2:300;
YpartN=-440:16*2:440;
%frameRate=1/300; %get frame rate from camera pulses

%plot z score or raw rates
zSc=0;



vbls = {'Right_speed' 'Left_speed' 'Nose_speed' 'Left_acc' 'Right_acc'  'Right_x_to_nose' 'Left_x_to_nose' 'Rot_speed' 'Rot_acc' 'IMU_speed' 'Right_y_d1' 'Left_y_d1'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SES = LK_Session_Info();
OUT.SES = SES;
OUT.neuron_quality_threshold = neuron_quality_threshold;


[~, string_pull_intervals_uSec,~,~,~,~,~] = LK_Combine_All_String_Pull_Motion_To_Table(Behavior_sFreq, false);
epoch_st_ed_uSec = [string_pull_intervals_uSec(1) - 2e6 string_pull_intervals_uSec(end) + 2e6 ]; % add a little padding.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load spikes and restrict to the times of interest.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[SP,TS_uS] = LK_Load_Spikes(neuron_quality_threshold,epoch_st_ed_uSec);
OUT.n_neurons = length(SP);


load('Filtered_Time_Stamped_Coordinates_Corrected_Ori');
load('good_string_pull_intervals_uSec.mat');

[PAW,~]=LK_process_paw_data(T3,good_string_pull_intervals_uSec);


frameRate=1/367;
%%
%Save positions at firing times and bin in x and y directions
for i=1:length(TS_uS)
    N(i).xy=array2table(interp1(PAW.Time_uSec,table2array(PAW),SP(i).t_uS));
    
    
    N(i).xy.Properties.VariableNames=PAW.Properties.VariableNames;
    
    N(i).firings.left=histcounts2(N(i).xy.Left_x,N(i).xy.Left_y,Xpart,Ypart);
    N(i).firings.right=histcounts2(N(i).xy.Right_x,N(i).xy.Right_y,Xpart,Ypart);
    N(i).firings.nose=histcounts2(N(i).xy.Nose_x,N(i).xy.Nose_y,Xpart,Ypart);
    N(i).firings.leftNose=histcounts2(N(i).xy.Left_x_to_nose,N(i).xy.Left_y_to_nose,XpartN,YpartN);
    N(i).firings.rightNose=histcounts2(N(i).xy.Right_x_to_nose,N(i).xy.Right_y_to_nose,XpartN,YpartN);
    
end

%Calc number of frames total in each bin
occ.left=histcounts2(PAW.Left_x,PAW.Left_y,Xpart,Ypart);
occ.right=histcounts2(PAW.Right_x,PAW.Right_y,Xpart,Ypart);
occ.nose=histcounts2(PAW.Nose_x,PAW.Nose_y,Xpart,Ypart);
occ.leftNose=histcounts2(PAW.Left_x_to_nose,PAW.Left_y_to_nose,XpartN,YpartN);
occ.rightNose=histcounts2(PAW.Right_x_to_nose,PAW.Right_y_to_nose,XpartN,YpartN);

% get occupancy time in each bin
occ.left=occ.left .* frameRate;
occ.right=occ.right .* frameRate;
occ.nose=occ.nose .* frameRate;
occ.leftNose=occ.leftNose .* frameRate;
occ.rightNose=occ.rightNose .* frameRate;
%%
% Create figure for occupancy for each extremity, sanity check #1
for i=1:length(SP)
    figure
    set(gcf, 'WindowState', 'maximized');
    
    subplot(2,3,1)
    imagesc(Xpart,Ypart,occ.right')
    title(sprintf("Right Paw Occupancy (s)"))
    axis xy
    colorbar
   
    subplot(2,3,2)
    imagesc(Xpart,Ypart,occ.nose')
    title(sprintf("Nose Occupancy (s)"))
    axis xy
    colorbar
    
    
    subplot(2,3,3)
    imagesc(Xpart,Ypart,occ.left')
    title(sprintf("Left Paw Occupancy (s)"))
    axis xy
    colorbar
    
    
    subplot(2,3,4)
    plot(PAW.Right_x,PAW.Right_y,'.','markersize',1,'color',[.3 .3 .3]);
    title(sprintf("Neuron %d Firing Locations: Right Paw",i))
    hold on;
    plot(N(i).xy.Right_x,N(i).xy.Right_y,'.','markersize',5,'color',[0 0 1])
    set(gca,'Ydir','reverse')
    hold off
    axis xy
    
    subplot(2,3,5)
    plot(PAW.Nose_x,PAW.Nose_y,'.','markersize',1,'color',[.3 .3 .3]);
    title(sprintf("Neuron %d Firing Locations: Nose",i))
    hold on;
    plot(N(i).xy.Nose_x,N(i).xy.Nose_y,'.','markersize',5,'color',[0 0 1])
    set(gca,'Ydir','reverse')
    hold off
    axis xy
    
    subplot(2,3,6)
    plot(PAW.Left_x,PAW.Left_y,'.','markersize',1,'color',[.3 .3 .3]);
    title(sprintf("Neuron %d Firing Locations: Left Paw",i))
    hold on;
    plot(N(i).xy.Left_x,N(i).xy.Left_y,'.','markersize',5,'color',[0 0 1])
    set(gca,'Ydir','reverse')
    hold off
    axis xy
    
    
    
    
    figure
    set(gcf, 'WindowState', 'maximized');
    
    subplot(2,2,1)
    imagesc(XpartN,YpartN,occ.rightNose')
    title(sprintf("Right Paw to Nose Occupancy (s)"))
    axis xy
    colorbar
    
    
    subplot(2,2,2)
    imagesc(XpartN,YpartN,occ.leftNose')
    title(sprintf("Left Paw to Nose Occupancy (s)"))
    axis xy
    colorbar
    
    
    
    subplot(2,2,3)
    plot(PAW.Right_x_to_nose,PAW.Right_y_to_nose,'.','markersize',1,'color',[.3 .3 .3]);
    title(sprintf("Neuron %d Firing Locations: Right Paw re Nose",i))
    hold on;
    plot(N(i).xy.Right_x_to_nose,N(i).xy.Right_y_to_nose,'.','markersize',5,'color',[0 0 1])
    set(gca,'Ydir','reverse')
    hold off
    axis xy
    
    
    
    subplot(2,2,4)
    plot(PAW.Left_x_to_nose,PAW.Left_y_to_nose,'.','markersize',1,'color',[.3 .3 .3]);
    title(sprintf("Neuron %d Firing Locations: Left Paw re Nose",i))
    hold on;
    plot(N(i).xy.Left_x_to_nose,N(i).xy.Left_y_to_nose,'.','markersize',5,'color',[0 0 1])
    set(gca,'Ydir','reverse')
    hold off
    axis xy
    
end

%%
% Create position plots for each spike per neuron, sanity check #2
for i=1:length(SP)
    figure
    set(gcf, 'WindowState', 'maximized');
    
    subplot(1,3,1)
    scatter(N(i).xy.Right_x,N(i).xy.Right_y)
    title(sprintf("Right Paw Position at Neuron %d firing",i))
    
    xlim([0 600])
    ylim([0 880])
    axis xy
    
    subplot(1,3,2)
    scatter(N(i).xy.Nose_x,N(i).xy.Nose_y)
    title(sprintf("Nose Position at Neuron %d firing",i))
    
    xlim([0 600])
    ylim([0 880])
    axis xy
    
    subplot(1,3,3)
    scatter(N(i).xy.Left_x,N(i).xy.Left_y)
    title(sprintf("Left Paw Position at Neuron %d firing",i))
    
    xlim([0 600])
    ylim([0 880])
    axis xy
    
    figure
    set(gcf, 'WindowState', 'maximized');
    
    subplot(1,2,1)
    scatter(N(i).xy.Right_x_to_nose,N(i).xy.Right_y_to_nose)
    title(sprintf("Right Paw Position re Nose at Neuron %d firing",i))
    
    xlim([-300 300])
    ylim([-440 440])
    axis xy
    
    subplot(1,2,2)
    scatter(N(i).xy.Left_x_to_nose,N(i).xy.Left_y_to_nose)
    title(sprintf("Left Paw Position re Nose at Neuron %d firing",i))
    
    xlim([-300 300])
    ylim([-440 440])
    axis xy
end
%%
%Create Fire Rate data


explodeThresh=.5; %threshold to detect erroneously high rates stimming from regular spike counts + low occupancy time
for i=1:length(SP)
    
    N(i).fireRate.right=N(i).firings.right ./ occ.right;
    N(i).fireRate.nose=N(i).firings.nose ./ occ.nose;
    N(i).fireRate.left=N(i).firings.left ./ occ.left;
    N(i).fireRate.rightNose=N(i).firings.rightNose ./ occ.rightNose;
    N(i).fireRate.leftNose=N(i).firings.leftNose ./ occ.leftNose;
    
    %set skewed high values steming from low occupancy and a coule spikes to nans    
    N(i).fireRate.right((N(i).fireRate.right>=explodeThresh/frameRate))=nan;
    N(i).fireRate.nose((N(i).fireRate.nose>=explodeThresh/frameRate))=nan;
    N(i).fireRate.left((N(i).fireRate.left>=explodeThresh/frameRate))=nan;
    N(i).fireRate.rightNose((N(i).fireRate.rightNose>=explodeThresh/frameRate))=nan;
    N(i).fireRate.leftNose((N(i).fireRate.leftNose>=explodeThresh/frameRate))=nan;
    
    
end

%%
%Create Fire Rate images
for i=1:length(SP)
    
    %first figure is for raw paw + nose positions
    figure
    set(gcf, 'WindowState', 'maximized');
    
    subplot(1,3,1)
    if zSc
        imagesc(Xpart,Ypart,zscore(N(i).fireRate.right'))
        title(sprintf("Right Paw Position and Neuron %d Firing Rate ZScore",i))
    else
        imagesc(Xpart,Ypart,N(i).fireRate.right')
        title(sprintf("Right Paw Position and Neuron %d Firing Rate",i))
    end
    
    xlim([0 600])
    ylim([0 880])
    colorbar
    caxis(prctile(N(i).fireRate.right(:),[1 98]))
    axis xy
    
    
    
    subplot(1,3,2)
    if zSc
        imagesc(Xpart,Ypart,zscore(N(i).fireRate.nose'))
        title(sprintf("Nose Position and Neuron %d Firing Rate ZScore",i))
    else
        imagesc(Xpart,Ypart,N(i).fireRate.nose')
        title(sprintf("Nose Position and Neuron %d Firing",i))
    end
    xlim([0 600])
    ylim([0 880])
    colorbar
    caxis(prctile(N(i).fireRate.nose(:),[1 98])) 
    axis xy
    
    
    subplot(1,3,3)
    if zSc
        imagesc(Xpart,Ypart,zscore(N(i).fireRate.left'))
        title(sprintf("Left Paw Position and Neuron %d Firing Rate ZScore",i))
    else
        imagesc(Xpart,Ypart,N(i).fireRate.left')
        title(sprintf("Left Paw Position and Neuron %d Firing Rate",i))
    end
    xlim([0 600])
    ylim([0 880])
    colorbar
    caxis(prctile(N(i).fireRate.left(:),[1 98])) 
    axis xy
    
    %second figure is for paw positions relative to nose
    figure
    set(gcf, 'WindowState', 'maximized');
    
    
    subplot(1,2,1)
    if zSc
        imagesc(XpartN,YpartN,zscore(N(i).fireRate.rightNose'))
        title(sprintf("Right Paw Position re Nose and Neuron %d Firing Rate ZScore",i))
    else
        imagesc(XpartN,YpartN,N(i).fireRate.rightNose')
        title(sprintf("Right Paw Position re Nose and Neuron %d Firing Rate",i))
    end
    
    colorbar
    caxis(prctile(N(i).fireRate.rightNose(:),[1 98]))
    
    
    axis xy
    
    subplot(1,2,2)
    if zSc
        imagesc(XpartN,YpartN,zscore(N(i).fireRate.leftNose'))
        title(sprintf("Left Paw Position re Nose and Neuron %d Firing Rate ZScore",i))
    else
        imagesc(XpartN,YpartN,N(i).fireRate.leftNose')
        title(sprintf("Left Paw Position re Nose and Neuron %d Firing Rate",i))
    end
    colorbar
    caxis(prctile(N(i).fireRate.leftNose(:),[1 98]))
    axis xy
end

%output edges and neural firing bins
OUT.Data=N;
OUT.Edges.X=Xpart;
OUT.Edges.Y=Ypart;
OUT.Edges.XN=XpartN;
OUT.Edges.YN=YpartN;

end

