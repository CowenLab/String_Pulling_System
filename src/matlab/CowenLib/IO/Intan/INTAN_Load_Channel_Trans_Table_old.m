function TT = INTAN_Load_Channel_Trans_Table(trans_table_file)
% loads the channel translation table from an excel spreadsheet
%
% e.g. trans_table_file = 'Channel_translation_tables_Plexon_128Ch_EIB_octrodes_Rat4.xlsx'
% Check version
[tmp,txt] = xlsread(trans_table_file,'ChannelTranslation','B1');
[num] = xlsread(trans_table_file);
switch txt{1}
    case 'v0.2'
        TT.nTrode_Num = num(:,1); % Unique ID of the ntrode (eg. stereo or octrode...)
        TT.Within_nTrode_Num = num(:,2); % channel within each nTrodes
        TT.Headstage_Num = num(:,3);
        TT.Within_Headstage_Num = num(:,6); % Channel within each headstage.
        TT.Amplipex_Headstage_Num = num(:,4); %Equivalent channel within amplipex headstage
        TT.Intan_Channel = num(:,7); % Channel on the intan system
        TT.Amplipex_Channel = num(:,5);
        TT.Is_Good = num(:,8); % 0 or 1
        TT.Cluster_Assignments = num(:,9); % common id for all channels that will be grouped for cluster cutting (e.g. if you have octrodes, you may want to split them into tetrodes for clustering, otherwise, if you have tetrodes, this should be sthe same as the nTrode_Num)
        TT.Is_LFP_Channel = num(:,10); % 0 or 1 - which channels will you keep as LFP?
    otherwise
        error('Unrecognized Channel translation file')
end
