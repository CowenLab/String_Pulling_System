function INTAN_Generate_Settings(template_isf, settings_xls,settings_fname)
%Renames channels in a settings file according to channel translation
%table. You really only need to use this once for every new hardware
%configuration or nTrode reassignment, just make sure the template ISF file
%is created with the amplifiers plugged in as operationally desired.

if nargin <3
    settings_fname = 'Settings.isf'
end

ISF = INTAN_Read_ISF_file(template_isf);
TT = INTAN_Load_Channel_Trans_Table(settings_xls);

if ISF.channels(1,1).signal_type ~= 0;
    error('Error: Template settings file contains no amplifier channels. You should make one using the desired hardware configuration.')
end

fprintf(1, '\n');
fprintf(1, ['Renaming channels according to ' settings_xls '\n']);

% Identify multitrode type
nameChar = [];
switch max(TT.Within_nTrode_Num)
    case 2
        nameChar = 'S'; %Stereotrode
    case 4
        nameChar = 'T'; %Tetrode
    case 8
        nameChar = 'O'; %Octrode
    otherwise
        error('Error: Unrecognized multitrode type');
end

% Name multitrode by type, name, wire identity, and LFP status eg "T12E4L"
% Also set enabled status

for s =  find(ISF.signal_group_num_channels(1:4));
    for i = 1:numel(ISF.channels(s,:))
        nativename = ISF.channels(s,i).native_channel_name;
        if(isempty(strfind(nativename,'AUX'))&& isempty(strfind(nativename,'VDD'))) %Don't assign AUX/VDD channels
            settingsindex = (1 + (ISF.channels(s,i).chip_channel)) + (32 * ((ISF.channels(s,i).board_stream)));
            [~,tableindex] = ismember(settingsindex,TT.Intan_Channel);
            if tableindex ~=0
                nameNtr = num2str(TT.nTrode_Num(tableindex),'%02u');
                nameWire = num2str(TT.Within_nTrode_Num(tableindex),'%02u');
                nameStr = [nameChar nameNtr 'E' nameWire];
                if TT.Is_LFP_Channel(tableindex)
                    nameStr = [nameStr 'L'];
                end
                ISF.channels(s,i).custom_channel_name = nameStr;
                % Set enabled status only if the "Is_Good" column in the translation table
                % contains good channels. If it is a "fresh" translation it won't and we
                % want to ignore this parameter
                if isequal(TT.Is_Good,zeros(length(TT.Is_Good),1)) && TT.Is_Good(tableindex) == 0
                    ISF.channels(s,i).enabled = 0;
                end
            end
        elseif(~isempty(strfind(nativename,'AUX')))
            switch(nativename(end))
                case '1'
                    ISF.channels(s,i).custom_channel_name = 'ACCEL_Y';
                case '2'
                    ISF.channels(s,i).custom_channel_name = 'ACCEL_Z';
                case '3'
                    ISF.channels(s,i).custom_channel_name = 'ACCEL_X';
                case '4'
                    ISF.channels(s,i).custom_channel_name = 'ACCEL_Y';
                case '5'
                    ISF.channels(s,i).custom_channel_name = 'ACCEL_Z';
                case '6'
                    ISF.channels(s,i).custom_channel_name = 'ACCEL_X';    
            end
        end
    end
end
fprintf(1, '     ...done\n');
INTAN_Write_ISF_file(ISF,settings_fname);
end