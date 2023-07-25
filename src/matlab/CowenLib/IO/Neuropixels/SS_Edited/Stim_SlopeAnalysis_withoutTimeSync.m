%SS LFP Analysis
tic;
%Look for %% To change input variables 

%%Data Dirs
PRM_RAT_DATA_DIR='F:\Data\vHPC_stim_mPFC_excitability_project\SinglePulseStim\10847';
PRM_SUB_FOLDER='mPFC_L5_bank0_g0';
PRM_ROOT_DATA_DIR=fullfile(PRM_RAT_DATA_DIR,PRM_SUB_FOLDER);
[~,root_folder] = fileparts(PRM_ROOT_DATA_DIR);
AP_FILE_DIR = fullfile(PRM_ROOT_DATA_DIR, [root_folder '_imec0']);

%Run CatGT for events only
PRM_EVENT_CHANNELS=[1 5];
NPXL_Extract_Events_With_CatGT_SS('PRM_ROOT_DATA_DIR', PRM_ROOT_DATA_DIR,...
     'PRM_EVENT_CHANNELS',PRM_EVENT_CHANNELS,...
        'PRM_INAROW',2,...
        'PRM_XA_THR1',0.8,...
        'PRM_XA_THR2',0.5);

%%
% CHANGE VALUES BELOW
%Load Stim Times
Stim_times_file=fullfile(PRM_ROOT_DATA_DIR,'mPFC_L5_bank0_g0_tcat.nidq.xa_5_0.txt');
Stim_times=readmatrix(Stim_times_file);
Stim_times_vHC=Stim_times(1:16); %%%Change this if more runs than 16. 
Stim_times_iHC=Stim_times(17:32);
%Change this when you want to run vHC vs iHC
Stim_times=Stim_times_vHC;


%Get Sample values from stim timestamps
NIDQ_meta_fname=strrep(PRM_SUB_FOLDER,'g0','g0_tcat.nidq.meta');
obj1 = SGLX_Class;
NIDQ.meta = obj1.ReadMeta(NIDQ_meta_fname,PRM_ROOT_DATA_DIR);

%Get meta files for LFP data
LFP_meta_fname=strrep(PRM_SUB_FOLDER,'g0','g0_t0.imec0.lf.meta');
LFP.meta=obj1.ReadMeta(LFP_meta_fname,AP_FILE_DIR);

%%
Slope=zeros(length(Stim_times),385);
%figure
%hold on
for stim =1:length(Stim_times)
    %Calculate sample times
    time_start=Stim_times(stim); %in s
    time_diff=0.4; %300 ms window

    LFP_Sample0=floor(time_start*str2double(LFP.meta.imSampRate));
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
        [~,min_idx]=min(LFP.data_Volts(ii,:));
        [~,max_idx]=max(LFP.data_Volts(ii,min_idx:end));

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

toc;

max_Slopes=max(Slope,[],2);
[~,ind]=max(max_Slopes);

