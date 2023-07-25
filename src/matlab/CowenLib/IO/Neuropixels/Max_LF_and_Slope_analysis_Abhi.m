%% get the max and min and slope

for stim =1:length(Stim_times)
    %Calculate sample times
    time_start=Stim_times(stim); %in s
    time_diff=0.1; %300 ms window
    
    LFP_Sample0=floor(time_start*str2double(LFP.meta.imSampRate));
    LFP_Sample_startafterstim = LFP_Sample0+8;
    LFP_nSamp=floor(1.0 * time_diff*str2double(LFP.meta.imSampRate));

    %AP_Sample0=str2double(AP.meta.firstSample)+(time_start*str2double(AP.meta.imSampRate));
    %AP_nSamp=time_diff*str2double(AP.meta.imSampRate);

    %Load LFP in sample range
    LFP.gain=250;
    LFP_binName=strrep(LFP_meta_fname,'.lf.meta','.lf.bin');
    LFP.data=obj1.ReadBin(LFP_Sample0,LFP_nSamp,LFP.meta,LFP_binName,AP_FILE_DIR);
    LFP.data_Volts=LFP.data.*(LFP.meta.imAiRangeMax/(LFP.meta.imMaxInt*LFP.gain));%in uV
    
    LFP.time=[time_start:(time_diff)/(LFP_nSamp-1):time_start+time_diff];%in ms
    LFP_sample_time=(LFP_Sample0+LFP_nSamp)/str2double(LFP.meta.imSampRate);

    All_LFP_data_V(stim,:,:)= LFP.data_Volts;
    
    %Plot post stim time
    %LFP.samples=1:LFP_nSamp;
    %plot(LFP.samples,LFP.data(1,:)+0.5*stim,'k');
    %xline(LFP.time(1,1),'r');
    %caxis([-100 100])
    
    %Find slope for each row
    [channel_cnt,~]=size(LFP.data_Volts);
    for ii=1:channel_cnt
        
        [~,min_idx]=min(LFP.data_Volts(ii,25:end));
        [~,max_idx]=max(LFP.data_Volts(ii,25:end));

        if min_idx > max_idx
            [~,min_idx] = min(LFP.data_Volts(ii,max_idx+24:end));
            min_idx = min_idx + (max_idx+23);
            max_idx = max_idx+24;
        elseif max_idx > min_idx
            [~,max_idx] = max(LFP.data_Volts(ii,min_idx+24:end));
            max_idx = max_idx + (min_idx+23);
            min_idx = min_idx+24;
        elseif max_idx == min_idx
            [~,max_idx] = max(LFP.data_Volts(ii,min_idx+24:end));
            max_idx = max_idx + (min_idx+23);
            min_idx = min_idx+24;
        end

        %Slope Calculation
        min_point=[LFP.time(min_idx),LFP.data_Volts(ii,min_idx)];
        max_point=[LFP.time(max_idx),LFP.data_Volts(ii,max_idx)];
        
        LFP_sec = LFP.time-LFP.time(1);

        min_point_all(stim,ii) = min_point(2); 
        min_time_all(stim,ii) = LFP_sec(min_idx);
        max_point_all(stim,ii) = max_point(2); 
        max_time_all(stim,ii) = LFP_sec(max_idx);
        Slope(stim,ii)=(max_point(2)-min_point(2))/(max_point(1)-min_point(1));
    end
end




%% create video of raw lfp across different stim currents
[sorted_current,sorted_idx] = sort(PRM.output_current_array);
% x_s = LFP.time-LFP.time(1);
% XIX = x_s < 0.1;
figure
for ii = 1:26
    figure
    caxis([-1.5 1.5 ])
    per_stim(:,:) = All_LFP_data_V(sorted_idx(ii),:,:);
    imagesc(LFP.time-LFP.time(1),[],per_stim)
    colorbar('Limits',[-2 2])
    xlabel('sec')
    ylabel('channels')
    %     hold on
    plot_vert_line_at_zero(.05)
    %     pause(.4)
    title(sprintf('mPFC L5 vHPC Stimulation Voltage %0.2f',PRM.output_current_array(sorted_idx(ii))))
    axis xy
end

%% time of max response in the dorsal inframlimbic area

infra_idx = [140:1:180];
infra_idx2 = [20:1:80];
why = mean(max_time_all(:,infra_idx2),2);
why=why(sorted_idx);
figure
scatter(sorted_current(3:end), why(3:end))
ylabel('mean time to LFP response from stim (s)')
xlabel('vHPC stimulation current')
title('Response time and voltage relationship mPFC L5 vHPC stim')
pubify_figure_axis
pf = polyfit(sorted_current(3:end), why(3:end),3);
x1 = linspace(min(sorted_current(3:end)), max(sorted_current(3:end)),16);
pv = polyval(pf,x1);
hold on
plot(x1,pv)
lsline



figure
scatter(PRM.output_current_array, nanmean(max_point_all(:,infra_idx),2))
ylabel('max LFP response')
xlabel('vHPC stimulation current')
title('Voltage and max LFP response relationship mPFC L5 vHPC stim Rat10858')
lsline
pubify_figure_axis

figure
scatter(PRM.output_current_array, nanmean(Slope(:,infra_idx2),2))
ylabel('Slope')
xlabel('vHPC stimulation current')
title('Voltage and Slope relationship mPFC L5 vHPC stim Rat10847')
lsline
pubify_figure_axis
