function INTAN_Write_ISF_file(ISF, output_file)

% Partially adapted from "read_Intan_RHD2000_file Version 1.3, 10 December 2013"
%
% Reads data structure of the kind created by "INTAN_Read_ISF_file" and
% writes it out as a .ISF amplifier settings file.
% Get Filenames

if nargin == 0
    error('Insufficient Input Arguments');
end

if nargin == 1
    output_file = 'Settings.isf';
end

fid = fopen(output_file, 'w');

data_file_main_version_number = ISF.versionMain;
data_file_secondary_version_number = ISF.versionSecondary;

fprintf(1, '\n');
fprintf(1, 'Writing *.isf Settings File, Version %d.%d\n', ...
    data_file_main_version_number, data_file_secondary_version_number);

% Write "magic number" so software will load settings file.
fwrite(fid, [1168839373],'uint32', 0, 'l');

% Write versioninfo
fwrite(fid, ISF.versionMain, 'int16', 0, 'l');
fwrite(fid, ISF.versionSecondary, 'int16', 0, 'l');



% Write out big stupid matrix
fwrite(fid, ISF.number_of_signal_groups, 'int16', 0, 'l');
for signal_group = 1:ISF.number_of_signal_groups
    fwrite_QString(fid, ISF.signal_group_name{signal_group});
    fwrite_QString(fid, ISF.signal_group_prefix{signal_group});
    fwrite(fid, ISF.signal_group_enabled(signal_group), 'int16', 0, 'l');
    fwrite(fid, ISF.signal_group_num_channels(signal_group), 'int16', 0, 'l');
    fwrite(fid, ISF.signal_group_num_amp_channels(signal_group), 'int16', 0, 'l');

    if (ISF.signal_group_num_channels(signal_group) > 0 && ISF.signal_group_enabled(signal_group) > 0)
            for signal_channel = 1:ISF.signal_group_num_channels(signal_group)
                fwrite_QString(fid, ISF.channels(signal_group,signal_channel).native_channel_name);
                fwrite_QString(fid, ISF.channels(signal_group,signal_channel).custom_channel_name);
                fwrite(fid, ISF.channels(signal_group,signal_channel).native_order, 'int16', 0, 'l');
                fwrite(fid, ISF.channels(signal_group,signal_channel).custom_order, 'int16', 0, 'l');
                fwrite(fid, ISF.channels(signal_group,signal_channel).signal_type, 'int16', 0, 'l');
                fwrite(fid, ISF.channels(signal_group,signal_channel).channel_enabled, 'int16', 0, 'l');
                fwrite(fid, ISF.channels(signal_group,signal_channel).chip_channel, 'int16', 0, 'l');
                fwrite(fid, ISF.channels(signal_group,signal_channel).board_stream, 'int16', 0, 'l');
                fwrite(fid, ISF.new_trigger_channel(signal_group,signal_channel).voltage_trigger_mode, 'int16', 0, 'l');
                fwrite(fid, ISF.new_trigger_channel(signal_group,signal_channel).voltage_threshold, 'int16', 0, 'l');
                fwrite(fid, ISF.new_trigger_channel(signal_group,signal_channel).digital_trigger_channel, 'int16', 0, 'l');
                fwrite(fid, ISF.new_trigger_channel(signal_group,signal_channel).digital_edge_polarity, 'int16', 0, 'l');
                fwrite(fid, ISF.channels(signal_group,signal_channel).electrode_impedance_magnitude, 'single', 0, 'l');
                fwrite(fid, ISF.channels(signal_group,signal_channel).electrode_impedance_phase, 'single', 0, 'l');
            end
     end
end

% Write user settings
fwrite(fid, ISF.sample_rate_combo_box, 'int16', 0, 'l');
fwrite(fid, ISF.yScale_combo_box, 'int16', 0, 'l');
fwrite(fid, ISF.tScale_combo_box, 'int16', 0, 'l');

% Write Notch Filter Setting
fwrite(fid, ISF.notch_filter_mode, 'int16', 0, 'l');

% Write Base Filename for Recorded Data
fwrite_QString(fid, ISF.save_base_filename);

% Write Recording Period (minutes) Before Starting New Data File
fwrite(fid, ISF.new_save_file_period, 'int16', 0, 'l');

% Write DSP Settings
fwrite(fid, ISF.dspEnabled, 'int16', 0, 'l');
fwrite(fid, ISF.desiredDspCutoffFreq, 'single', 0, 'l');
fwrite(fid, ISF.desiredLowerBandwidth, 'single', 0, 'l');
fwrite(fid, ISF.desiredUpperBandwidth, 'single', 0, 'l');
fwrite(fid, ISF.desiredImpedanceFreq, 'single', 0, 'l');
fwrite(fid, ISF.actualImpedanceFreq, 'single', 0, 'l');
fwrite(fid, ISF.impedanceFreqValid, 'int16', 0, 'l');

% Write DAC Settings
fwrite(fid, ISF.dacGainSlider, 'int16', 0, 'l');
fwrite(fid, ISF.dacNoiseSuppressSlider, 'int16', 0, 'l');

% Write DAC Channels thing.
for ix = 1:8
    fwrite(fid, ISF.dacenabled(ix), 'int16', 0, 'l');
    fwrite_QString(fid, ISF.dacnames{ix});
end

% Write Fast Settle Enabled
fwrite(fid, ISF.fastSettleEnabled, 'int16', 0, 'l');

% Write PlotPointsMode
fwrite(fid, ISF.plotPointsCheckBox, 'int16', 0, 'l');

% Notes
fwrite_QString(fid,ISF.notes.note1);
fwrite_QString(fid,ISF.notes.note2);
fwrite_QString(fid,ISF.notes.note3); 

% Write Ports enabled thing.
for i=1:6
     fwrite(fid, ISF.portenabled1(i), 'int16', 0, 'l');
     fwrite(fid, ISF.portenabled2(i), 'int16', 0, 'l');
end

%Version-Specific Stuff

% Write Version 1.1 Stuff
if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 1) || (data_file_main_version_number > 1))
    fwrite(fid, ISF.saveTemp, 'int16', 0, 'l');
end

% Write Version 1.2 Stuff
if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 2) || (data_file_main_version_number > 1))
    fwrite(fid, ISF.recordTriggerChannel, 'int16', 0, 'l');
    fwrite(fid, ISF.recordTriggerPolarity, 'int16', 0, 'l');
    fwrite(fid, ISF.recordTriggerBuffer, 'int16', 0, 'l');
    
    fwrite(fid, ISF.saveFormat, 'int16', 0, 'l');
    fwrite(fid, ISF.dacLockToSelectedBox, 'int16', 0, 'l');
end

% Write Version 1.3 Stuff
if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 3) || (data_file_main_version_number > 1))
    for i = 1:8
        fwrite(fid, ISF.dacThresholdSpinBox(i), 'int32', 0, 'l');
    end
    fwrite(fid, ISF.saveTtlOut, 'int16', 0, 'l');
    fwrite(fid, ISF.enableHighpassFilter, 'int16', 0, 'l');
    fwrite(fid, ISF.highpassFilterLine, 'single', 0, 'l');
end

% Write Version 1.4 Stuff
if ((data_file_main_version_number == 1 && data_file_secondary_version_number >= 4) || (data_file_main_version_number > 1))
    fwrite(fid, ISF.externalFastSettleCheckBox, 'int16', 0, 'l');
    fwrite(fid, ISF.externalFastSettleSpinBox, 'int16', 0, 'l');
    for i = 1:4
        for ii = 1:4
            switch i
                case 1
                    fwrite(fid, ISF.auxDigOutEnabled(ii), 'int16', 0, 'l');
                case 2
                    fwrite(fid, ISF.auxDigOutChannel(ii), 'int16', 0, 'l');
                case 3
                    fwrite(fid, ISF.manualDelayEnabled(ii), 'int16', 0, 'l');
                case 4
                    fwrite(fid, ISF.manualDelay(ii), 'int16', 0, 'l');
            end
        end
    end
end

fclose(fid);
fprintf(1, '     ...done\n');

    function a = fwrite_QString(fid, a)
        Length = length(a) * 2; %Convert to unicode bytes
        if Length == 0
            Length = hex2num('41efffffffe00000');
        end
        fwrite(fid, Length ,'uint32', 0, 'l');
        fwrite(fid, a, 'uint16', 0, 'l');
    end

end