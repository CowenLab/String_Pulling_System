function IF = INTAN_Update_Header_From_Trans_Table(IF,TT)
%Updates loaded header channel information according to loaded translation
%table. Use this to organize your closet post-hoc.

%Find out ntrode assignment
badchannels = [];
type = 'na';
switch max(TT.Within_nTrode_Num)
    case 2
        type = 'Stereotrode';
    case 4
        type = 'Tetrode';
    case 8
        type = 'Octrode';
end

for i = 1:numel(IF.amplifier_channels)
    IF.amplifier_channels(i).multitrode_type = 'na';
    IF.amplifier_channels(i).multitrode_index = 0;
    IF.amplifier_channels(i).multitrode_assignment = 0;
    IF.amplifier_channels(i).is_LFP = 0;
    
    headerindex = getIntanChannelNumber(IF,i);
    [~,tableindex] = ismember(headerindex,TT.Intan_Channel);
    if tableindex > 0
        IF.amplifier_channels(i).multitrode_type = type;
        IF.amplifier_channels(i).multitrode_index = TT.Within_nTrode_Num(tableindex);
        IF.amplifier_channels(i).multitrode_assignment = TT.nTrode_Num(tableindex);
        if isfield(IF.amplifier_channels(i),'Region_Label')
            IF.amplifier_channels(i).Region_Label = TT.Region_Label(tableindex);
        else
            IF.amplifier_channels(i).Region_Label = '';
        end
        IF.amplifier_channels(i).is_LFP = TT.Is_LFP_Channel(tableindex);
        if ~TT.Is_Good(tableindex)
            badchannels = [badchannels i];
        end
    end
end

IF.amplifier_channels(badchannels) = [];
IF.spike_triggers(badchannels) = [];
if(isfield(IF,'amplifier_data'))
    IF.amplifier_data(badchannels,:) = [];
end

end

