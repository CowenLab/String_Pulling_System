function out = INTAN_Extract_Accel(IF)
%Process auxillary accelerometer data. For now all this does is subtract
%out the correction for gravity.

%Note that this assumes the specified
%aux channels have been named according to the scheme:
%"ACCEL_X, ACCEL_Y, ACCEL_Z" etc.
% X,Y,and Z in these names correspond
% to the animal's orientation, not the board's orientation in the
% manufacturer documentation.

if nargin == 0
    IF = INTAN_Read_RHD_file();
end

%Empirically determined according to manufacturer documentation.
%With some caveats: we are performing operations on raw data, not
%unit-converted data. So the correction values should also be provided
%here in raw units.

GRAVITY_BIAS(1) = 47700; %Animal X zero-g bias
GRAVITY_BIAS(2) = 55100; %Animal Y zero-g bias
GRAVITY_BIAS(3) = 44900; %Animal Z zero-g bias

SENSITIVITY(1) = -9200; %Animal X sensitivity
SENSITIVITY(2) = 1850; %Animal Y sensitivity
SENSITIVITY(3) = 8270; %Animal Z sensitivity

%Also, the correction values were determined for the normative animal
%orientation (Hardware minus could become animal plus), hence the negative
%number on the X axis (board Z) to "flip" the accelerometer traces to match
%animal orientation. Might want to double check these values or re-do the
%calibration now that the system is on a different tether with different
%supply voltages, however slight.

%get channel indices
channels{1} = cellfind('ACCEL_X'); %X Channels
channels{2} = cellfind('ACCEL_Y'); %Y Channels
channels{3} = cellfind('ACCEL_Z'); %Z Channels

for i = 1:3
    curdim = channels{i};
    for ii = 1:numel(curdim)
        curname = IF.aux_input_channels(curdim(ii)).custom_channel_name;
        curfile = ['aux-' IF.aux_input_channels(curdim(ii)).native_channel_name '.dat '];
        cpbase = [curname '.datacc']
        cpfile = ['1_' cpbase];
        
        dupcount = 2;
        while exist(cpfile,'file')
            cpfile = [num2str(dupcount) '_' cpbase];
            dupcount = dupcount+1;
        end
        
        fprintf('Copying accelerometer data to %s\n',cpfile);
        copyfile(curfile,cpfile);
       
        ChannelTransform(cpfile,-GRAVITY_BIAS(i),1/SENSITIVITY(i));
    end
end

    function out = cellfind(cmp)
        cellnames = {IF.aux_input_channels.custom_channel_name};
        cellind = strfind(cellnames,cmp);
        out = find(~cellfun(@isempty,cellind));
    end

end