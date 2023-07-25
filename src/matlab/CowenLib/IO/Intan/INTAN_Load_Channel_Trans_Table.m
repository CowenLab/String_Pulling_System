function TT = INTAN_Load_Channel_Trans_Table(trans_table_file)
% loads the channel translation table from an excel spreadsheet
% Note: 100% identiacal to the AMPX version this one just makes sure we
% have a self-contained codebase if one moves without the other.

% e.g. trans_table_file = 'Channel_translation_tables_Plexon_128Ch_EIB_octrodes_Rat4.xlsx'
% Check version
[tmp,txt] = xlsread(trans_table_file,'ChannelTranslation','B1');
[num,~,raw] = xlsread(trans_table_file);
switch txt{1}
    case 'v0.1'
        TT.nTrode_Num = num(:,1); % Unique ID of the ntrode (eg. stereo or octrode...)
        TT.Within_nTrode_Num = num(:,2); % channel within each nTrodes
        TT.Headstage_Num = num(:,3);
        TT.Within_Headstage_Num = num(:,4); % Channel within each headstage.
        TT.Amplipex_Channel = num(:,5); % Channel on the amplipex system
        TT.Is_Good = num(:,6); % 0 or 1
        TT.Cluster_Assignments = num(:,7); % common id for all channels that will be grouped for cluster cutting (e.g. if you have octrodes, you may want to split them into tetrodes for clustering, otherwise, if you have tetrodes, this should be sthe same as the nTrode_Num)
        % NOTE: make this -1 if you do not want
        % to cluster cut this channel (e.g. it's
        % just an LFP channel or EMG channel.
        TT.Is_LFP_Channel = num(:,8); % 0 or 1 - which channels will you keep as LFP?
    case 'v0.2'
        TT.nTrode_Num = num(:,9); % Unique ID of the ntrode (eg. stereo or octrode...)
        TT.Within_nTrode_Num = num(:,2); % channel within each nTrodes
        TT.Headstage_Num = num(:,3);
        TT.Within_Headstage_Num = num(:,4); % Channel within each headstage.
        TT.Amplipex_Channel = num(:,5); % Channel on the amplipex system
        TT.Intan_Channel = num(:,7); % Channel on the amplipex system
        TT.Is_Good = num(:,8); % 0 or 1
        if Cols(num) < 11
            TT.Cluster_Assignments = nan*num(:,8); % THERE MAY BE NO CLUSTER ASSIGNMENT in this version (usually)
        else
            TT.Cluster_Assignments = num(:,11); % THERE MAY BE NO CLUSTER ASSIGNMENT in this version (usually)
        end
        % Assume that the 12th column might have some text labels for each
        % channels.
        for iR = 1:Rows(num)
           TT.Region_Label{iR} = raw{iR+2,12}; 
        end
        %%Sorry Mike, this was JP again:
%         TT.Cluster_Assignments = num(:,11); % common id for all channels that will be grouped for cluster cutting (e.g. if you have octrodes, you may want to split them into tetrodes for clustering, otherwise, if you have tetrodes, this should be sthe same as the nTrode_Num)
%         TT.Has_Spikes = num(:,12); % common id for all channels that will be grouped for cluster cutting (e.g. if you have octrodes, you may want to split them into tetrodes for clustering, otherwise, if you have tetrodes, this should be sthe same as the nTrode_Num)
%         TT.Depth_mm = num(:,13); % common id for all channels that will be grouped for cluster cutting (e.g. if you have octrodes, you may want to split them into tetrodes for clustering, otherwise, if you have tetrodes, this should be sthe same as the nTrode_Num)
%         TT.Location_str = raw(3:end,14); % common id for all channels that will be grouped for cluster cutting (e.g. if you have octrodes, you may want to split them into tetrodes for clustering, otherwise, if you have tetrodes, this should be sthe same as the nTrode_Num)
        % NOTE: make this -1 if you do not want
        % to cluster cut this channel (e.g. it's
        % just an LFP channel or EMG channel.
        TT.Is_LFP_Channel = num(:,10); % 0 or 1 - which channels will you keep as LFP?
    case 'v2' % This is actually an older version with weird versioning.
        TT.nTrode_Num = num(:,9); % Unique ID of the ntrode (eg. stereo or octrode...)
        TT.Within_nTrode_Num = num(:,10); % channel within each nTrodes
        TT.Headstage_Num = num(:,3);
        TT.Within_Headstage_Num = num(:,4); % Channel within each headstage.
        TT.Amplipex_Channel = num(:,5); % Channel on the amplipex system
        TT.Intan_Channel = num(:,5); % Channel on the amplipex system
        TT.Is_Good = num(:,6); % 0 or 1
        TT.Cluster_Assignments = num(:,7); % common id for all channels that will be grouped for cluster cutting (e.g. if you have octrodes, you may want to split them into tetrodes for clustering, otherwise, if you have tetrodes, this should be sthe same as the nTrode_Num)
        % NOTE: make this -1 if you do not want
        % to cluster cut this channel (e.g. it's
        % just an LFP channel or EMG channel.
        TT.Is_LFP_Channel = num(:,8); % 0 or 1 - which channels will you keep as LFP?

    otherwise
        error('Unrecognized Channel translation file')
end
