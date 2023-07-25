function TT = INTAN_Update_Channel_Trans_Table(ch_translation_table_fname,IF)
%Update channel translation table from amplifier metadata

if nargin <2
    IF = INTAN_Read_RHD_file();
end

if nargin <1
    d = dir(fullfile(pwd,'Channel_translation*.xlsx'));
    if length(d) > 1
        error('too many channel translation tables. There can be only one.')
    end
    ch_translation_table_fname = fullfile(pwd,d(1).name);
    
    IF = INTAN_Read_RHD_file();
end

% Load Channel Translation Table
TT = INTAN_Load_Channel_Trans_Table(ch_translation_table_fname);

% Set all to zero, add back channels by matching index to "true" name
TT.Is_Good = zeros(size(TT.Is_Good));
%TT.Is_LFP_Channel = zeros(size(TT.Is_LFP_Channel));

% Barbarian for-loop to set the "values that change" on the translation
% table.
TT.Cluster_Assignments = zeros(length(TT.Is_Good),1)*nan;

for i = 1:numel(IF.amplifier_channels)
    headerindex = getIntanChannelNumber(IF,i);
    [~,tableindex] = ismember(headerindex,TT.Intan_Channel);
    if headerindex > 0
        TT.Is_Good(tableindex) = 1;
        if ~strcmp(IF.amplifier_channels(i).multitrode_type,'na');
            TT.Cluster_Assignments(tableindex) = IF.amplifier_channels(i).multitrode_assignment;
        end
        if IF.amplifier_channels(i).is_LFP == 1
            TT.Is_LFP_Channel(tableindex) = 1;
        end
    end
end

%Write back to XLSX file
changes = [TT.Is_Good TT.Cluster_Assignments TT.Is_LFP_Channel];
range = ['H3:J' num2str(2+length(changes))];

[STATUS,MESSAGE] = xlswrite(ch_translation_table_fname, changes, range);
if ~STATUS
    disp(MESSAGE);
end

end