function [outputArg1,outputArg2] = DLC_Create_Labeled_Video(varargin)
%DLC_CREATE_LABELED_VIDEO Summary of this function goes here
%   Detailed explanation goes here



folders=split(pwd,'\');
P.session=str2double(folders{end});
P.rat=folders{end-1};
P.rat=str2double(P.rat(end-2:end));
vidStart=nan;
vidStop=nan;
frNo=1;
i=1;
trailpoints=367*2;
suppInfo=false;

LW=3;

vid_path=fullfile('G:\DATA\LID_Ketamine_SingleUnit_R56',num2str(P.rat),num2str(P.session),[num2str(P.session) '.mp4'])
out_path=fullfile('G:\DATA\LID_Ketamine_SingleUnit_R56',num2str(P.rat),num2str(P.session),'Labeled_Videos');
if ~exist(out_path)
    mkdir(out_path)
end


addpath(vid_path)
video=VideoReader(vid_path);
%coords=load('Filtered_Time_Stamped_Coordinates.mat');
%coords=coords.T2;

% if ~exist('good_string_pull_intervals_uSec.mat','file')
%     LK_Determine_good_pull_bouts
% end

load good_string_pull_intervals_uSec.mat
coords=load('Filtered_Time_Stamped_Coordinates_Corrected_Ori.mat');
coords=coords.T3;
S=size(coords);

if length(varargin)==2
    vidStart=cell2mat(varargin(1));
    vidStop =cell2mat(varargin(2));
    writer=VideoWriter(fullfile(out_path,[num2str(P.session) '_Labeled']), 'MPEG-4')
elseif length(varargin)==3
    vidStart=cell2mat(varargin(1));
    vidStop =cell2mat(varargin(2));
    writer=VideoWriter(fullfile(out_path,[num2str(P.session) '_' char(varargin(3))]), 'MPEG-4')
else
    vidStart=1;
    vidStop=S(1);
    writer=VideoWriter(fullfile(out_path,[num2str(P.session) '_Labeled']), 'MPEG-4')
end
writer.FrameRate=15;
writer.Quality=100;
open(writer)


[PAW,~]=LK_process_paw_data(coords,good_string_pull_intervals_uSec);
PXmap   =  [386,386,387];
pxPerCm=median(PXmap)/10;

if suppInfo
    Behavior_sFreq=100;
    neuron_quality_threshold=2;
    binSize=50;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Load spikes and restrict to the times of interest.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [MT, string_pull_intervals_uSec,~,~,~,~,EVENTS] = LK_Combine_All_String_Pull_Motion_To_Table(Behavior_sFreq, false);
    epoch_st_ed_uSec = [string_pull_intervals_uSec(1) - 2e6 string_pull_intervals_uSec(end) + 2e6 ]; % add a little padding.
    
    [SP,TS_uS] = LK_Load_Spikes(neuron_quality_threshold,epoch_st_ed_uSec);
    OUT.n_neurons = length(SP);
    
    [NT,~,NT_t_uS] = Bin_and_smooth_ts_array(TS_uS,binSize);
%         NT=gpuArray(NT);
%         NT_t_uS=gpuArray(NT_t_uS);
    % %     flat=[NT_t_uS',sum(NT,2)];
end






for i=vidStart:vidStop
    if mod(frNo,5000)==0
        fprintf("Now on frame: %d \n",i)
    end
    %frame=gpuArray(readFrame(video));
    frame=gpuArray(read(video,i));
    
    figure('visible', 'off')
    if suppInfo
        tiledlayout(3,2);
        nexttile(1,[3 1])
    end
    
    
    imagesc(flipud(frame));
    %     truesize
    
    axis xy
    hold on
    
    if ~isnan(coords.Nose_x(i))
        scatter(coords.Nose_x(i),coords.Nose_y(i),150,'y','LineWidth',LW)
        hold on
    end
    if ~isnan(coords.Left_x(i))
        scatter(coords.Left_x(i),coords.Left_y(i),150,'b','LineWidth',LW)
        hold on
    end
    if ~isnan(coords.Right_x(i))
        scatter(coords.Right_x(i),coords.Right_y(i),150,'r','LineWidth',LW)
    end
    hold off
    title("Paw and Nose Tracking")
    
    if (i> trailpoints)
        if suppInfo
            %paw speed
            nexttile
            plot(PAW.Time_uSec(i-trailpoints:i)/(1e6),PAW.Right_speed(i-trailpoints:i)/(pxPerCm*100),'r')
            hold on
            plot(PAW.Time_uSec(i-trailpoints:i)/(1e6),PAW.Left_speed(i-trailpoints:i)/(pxPerCm*100),'b')
            hold off
            title("Paw Speeds")
            ylabel("Speed (m/s)")
            xlabel("Time (s)")
            ylim([0 2])
            xlim([PAW.Time_uSec(i-trailpoints)/(1e6) PAW.Time_uSec(i+floor(trailpoints/9))/(1e6)])
            legend({'Right Paw' 'Left Paw'})
            
            %paw accel
            nexttile
            plot(PAW.Time_uSec(i-trailpoints:i)/(1e6),PAW.Right_acc(i-trailpoints:i)/(pxPerCm*100),'r')
            hold on
            plot(PAW.Time_uSec(i-trailpoints:i)/(1e6),PAW.Left_acc(i-trailpoints:i)/(pxPerCm*100),'b')
            hold off
            title("Paw Acceleration")
            ylabel("Acceleration (m/s^2)")
            xlabel("Time (s)")
            legend({'Right Paw' 'Left Paw'})
            ylim([-0.15 0.15])
            xlim([PAW.Time_uSec(i-trailpoints)/(1e6) PAW.Time_uSec(i+floor(trailpoints/9))/(1e6)])
            
            
            %neurons
            %[nInterest,~]=Restrict(flat,PAW.Time_uSec(i-trailpoints),PAW.Time_uSec(i));
            [nInterest,~]=Restrict([NT_t_uS',NT],PAW.Time_uSec(i-trailpoints),PAW.Time_uSec(i));
            nexttile
            %plot(nInterest(:,1)/(1e6),nInterest(:,2))
            
            for neuron=2:size(nInterest,2)
                %scatter(nInterest(nInterest(:,neuron)>0,1),nInterest(nInterest(:,neuron)>0,neuron),20)
                scatter(nInterest(nInterest(:,neuron)>0,1)/(1e6),neuron*ones(sum(nInterest(:,neuron)>0),1),30,'.k')
                hold on
            end
            
            hold off
            set(gca,'YDir','reverse')
            title("Ensemble Action Potentials")
            xlabel("Time (s)")
            ylabel("Neuron")
            ylim([0 size(nInterest,2)-1])
            
            
            
        end
    end
    
    
    set(gcf,'Position',[299          32        1411         964])
    img=getframe(gcf);
    writeVideo(writer,img);
    
    
    close
    
    frNo=frNo+1;
end

%% Save video
%    writer=VideoWriter(fullfile(out_path,[num2str(i) '_Labeled']), 'MPEG-4')
%writer.FrameRate=15;
%    open(writer)
%     for iF=1:j
%
%         f=Frames(i,iF);
%         writeVideo(writer,f.data');
%
%     end
%    writeVideo(writer,Frames.data);

close(writer)
%    clear Pull



end

