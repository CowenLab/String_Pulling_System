function INTAN_Read_Multiple_RHD2000_files(fname_root)
% INPUT: name of file base. For example: 'L18_L21_W42_W43_20hr'
%  if no file base is provided, then all rhd files in the present directory
%  will be used.
% OUTPUT: spits out the files in to a unique file for each channel.
%  no output variable. No bin output (to do)
%
% test: C:\Users\Stephen Cowen\Box Sync\Cowen Laboratory\!Projects\Intan_system\Bin\Intan Interface\TestData\INTAN_TEST_140401_080758.rhd
%
% Cowen 2018 modified from Lindsey code.
if nargin == 0
    fname_root = ''; % load all files in this directory.
end
[d_path,fname_root] = fileparts(fname_root);
if ~isempty(d_path)
    past_dir = pwd;
    chdir(d_path)
else
    d_path = '';
end

d=dir(sprintf('%s*.rhd',fname_root));
%quickly check that nothing is out of order
for ifile=1:length(d)-1
    num1=d(ifile+1).name(end-9:end-4);
    time_next=str2double(num1);
    num2=d(ifile).name(end-9:end-4);
    time_now=str2double(num2);
    if time_now>=time_next
        warning('Times are possibly out of order-check!')
    end
end

% Open the first one just to get the info...
O = INTAN_Read_RHD2000_file(fullfile(d_path,d(1).name));
ch_names = {O.amplifier_channels.native_channel_name}.';
prefix = 'amp-';

%% Start with the dat files.
fp_chan = zeros(1,length(ch_names));
for ichan=1:length(ch_names)
    fp_chan(ichan)=fopen([prefix ch_names{ichan} '.dat'],'w');
end
fp_time = fopen('time.dat','w');
%%
for ifile=1:length(d)
    O = INTAN_Read_RHD2000_file(d(ifile).name);
    % write out the time.
    fwrite(fp_time,O.t_amplifier,'uint32'); % save time as well. uint32 (40 hrs) vs. int32 (20 hrs). I chose uint32.
    % write out the data.
    assert(isequal(length(fp_chan),length(ch_names)), 'diff number of chan and dats, may not be writing to correct file');
    for ichan=1:length(fp_chan)
        fwrite(fp_chan(ichan),O.amplifier_data(ichan,:),'int16'); % here its only giving me like one number
    end
end
fclose all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Do the same with the bin data...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ch_names = {O.board_dig_in_channels.native_channel_name}.';
prefix = 'board-';

%% bin INPUT
fp_chan = zeros(1,length(ch_names));
for ichan=1:length(ch_names)
    fp_chan(ichan)=fopen([prefix ch_names{ichan} '.dat'],'w');
end
%
for ifile=1:length(d)
    O = INTAN_Read_RHD2000_file(d(ifile).name);
    assert(isequal(length(fp_chan),length(ch_names)), 'diff number of chan and dats, may not be writing to correct file');
    for ichan=1:length(ch_names)
        fwrite(fp_chan(ichan),O.board_dig_in_data(ichan,:),'uint16'); % here its only giving me like one number
    end
end
fclose all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% aux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ch_names = {O.aux_input_channels.native_channel_name}.';
prefix = 'aux-';

fp_chan = zeros(1,length(ch_names));
for ichan=1:length(ch_names)
    fp_chan(ichan)=fopen([prefix ch_names{ichan} '.dat'],'w');
end
%
for ifile=1:length(d)
    O = INTAN_Read_RHD2000_file(d(ifile).name);
    assert(isequal(length(fp_chan),length(ch_names)), 'diff number of chan and dats, may not be writing to correct file');
    for ichan=1:length(ch_names)
        fwrite(fp_chan(ichan),O.amplifier_data(ichan,:),'uint16'); % here its only giving me like one number
    end
end
fclose all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% time: I think the most recent version is int32 and not uint32. This may need some checking. Problem with int32 is that you only get 19.884 hours max. In contrast, uint32 gets you almost 40 hours.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% O.t_amplifier
% fp_chan = fopen('time.dat','w');
% fwrite(fp_chan,O.t_amplifier,'uint32');
% fclose(fp_chan);

if ~isempty(d_path)
    chdir(past_dir)
end