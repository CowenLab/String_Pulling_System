%SS LFP Analysis

%Run TPrime
PRM_ROOT_DATA_DIR='F:\Data\vHPC_stim_mPFC_excitability_project\vHC_StimCoordinate_test\10819\mPFC_L23_vHC_AP1_g0';
PRM_AlignSpikes=false;
EVT_Channels=[1 5]';
EVT_Channel_Names=cell2mat({'ANLG_1', 'STIM_5'}');


[status,cmdout] = NPXL_Sync_With_TPrime_SS('PRM_ROOT_DATA_DIR',PRM_ROOT_DATA_DIR,...
   'PRM_AlignSpikes',PRM_AlignSpikes );